-- ============================================================
-- 公司工资管理系统 - 存储过程与函数脚本
-- 数据库：TongyhMIS08 (openGauss)
-- 命名规范：函数 fn_tyh_<名称>08
-- 说明：2个核心存储过程 — 用户登录认证、员工工资计算
-- ============================================================

-- ============================================================
-- 1. 密码哈希函数
--    使用SHA256替代SM3（生产环境需替换为国密SM3算法）
-- ============================================================
CREATE OR REPLACE FUNCTION fn_tyh_HashPwd08(pwd VARCHAR)
RETURNS VARCHAR AS $$
BEGIN
    -- Use MD5 as hash (production should use SM3 via external extension)
    RETURN MD5(pwd);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================
-- 2. 密码复杂度校验
--    要求：8位以上，含数字、大小写字母、特殊字符
-- ============================================================
CREATE OR REPLACE FUNCTION fn_tyh_CheckPwd08(pwd VARCHAR)
RETURNS BOOLEAN AS $$
BEGIN
    IF LENGTH(pwd) < 8 THEN
        RAISE EXCEPTION '密码长度至少8位';
    END IF;
    IF pwd !~ '[0-9]' THEN
        RAISE EXCEPTION '密码必须包含数字';
    END IF;
    IF pwd !~ '[a-z]' THEN
        RAISE EXCEPTION '密码必须包含小写字母';
    END IF;
    IF pwd !~ '[A-Z]' THEN
        RAISE EXCEPTION '密码必须包含大写字母';
    END IF;
    IF pwd !~ '[!@#$%^&*()_+\-=\[\]{}|;:''",.<>/?`~]' THEN
        RAISE EXCEPTION '密码必须包含特殊字符';
    END IF;
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- 3. 个人所得税计算（月度超额累进税率）
--    应纳税所得额 = 总收入 - 5000 - 社保 - 公积金 - 专项月均
-- ============================================================
CREATE OR REPLACE FUNCTION fn_tyh_CalcTax08(
    p_income   NUMERIC,
    p_shebao   NUMERIC,
    p_gjj      NUMERIC,
    p_special  NUMERIC
)
RETURNS NUMERIC AS $$
DECLARE
    v_taxable NUMERIC;
    v_tax     NUMERIC := 0;
BEGIN
    v_taxable := p_income - 5000 - p_shebao - p_gjj - p_special;
    IF v_taxable <= 0 THEN RETURN 0; END IF;

    IF    v_taxable <= 3000  THEN v_tax := ROUND(v_taxable * 0.03, 2);
    ELSIF v_taxable <= 12000 THEN v_tax := ROUND(v_taxable * 0.10 - 210, 2);
    ELSIF v_taxable <= 25000 THEN v_tax := ROUND(v_taxable * 0.20 - 1410, 2);
    ELSIF v_taxable <= 35000 THEN v_tax := ROUND(v_taxable * 0.25 - 2660, 2);
    ELSIF v_taxable <= 55000 THEN v_tax := ROUND(v_taxable * 0.30 - 4410, 2);
    ELSIF v_taxable <= 80000 THEN v_tax := ROUND(v_taxable * 0.35 - 7160, 2);
    ELSE                         v_tax := ROUND(v_taxable * 0.45 - 15160, 2);
    END IF;

    RETURN GREATEST(v_tax, 0);
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- ★ 存储过程 1：用户登录认证
--    验证用户名密码，处理锁定/解锁，记录登录日志
-- ============================================================
CREATE OR REPLACE FUNCTION fn_tyh_UserLogin08(
    p_username VARCHAR,
    p_password VARCHAR
)
RETURNS TABLE(
    tyh_Success08 BOOLEAN,
    tyh_Message08 TEXT,
    tyh_EnoOut08  VARCHAR,
    tyh_Roles08   TEXT
) AS $$
DECLARE
    v_rec       Tongyh_Uspa08%ROWTYPE;
    v_encrypted VARCHAR(255);
    v_roles     TEXT;
BEGIN
    -- 查找用户
    BEGIN
        SELECT * INTO STRICT v_rec FROM Tongyh_Uspa08 WHERE tyh_Username08 = p_username;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN QUERY SELECT FALSE, '用户不存在', NULL::VARCHAR, NULL::TEXT;
            RETURN;
    END;

    -- 检查是否锁定
    IF v_rec.tyh_LockTime08 IS NOT NULL THEN
        IF v_rec.tyh_LockTime08 > CURRENT_TIMESTAMP THEN
            RETURN QUERY SELECT FALSE,
                '账户已锁定至 ' || TO_CHAR(v_rec.tyh_LockTime08, 'YYYY-MM-DD HH24:MI:SS'),
                NULL::VARCHAR, NULL::TEXT;
            RETURN;
        ELSE
            -- 锁定过期，自动清除
            UPDATE Tongyh_Uspa08
            SET tyh_LockTime08 = NULL, tyh_FailedAttempts08 = 0
            WHERE tyh_Username08 = p_username;
        END IF;
    END IF;

    -- 验证密码
    v_encrypted := fn_tyh_HashPwd08(p_password);

    IF v_encrypted = v_rec.tyh_Encryptedpassword08 THEN
        -- 登录成功
        UPDATE Tongyh_Uspa08 SET tyh_FailedAttempts08 = 0
        WHERE tyh_Username08 = p_username;

        -- 获取角色列表
        SELECT STRING_AGG(r.tyh_RoleName08, ', ' ORDER BY r.tyh_RoleName08)
        INTO v_roles
        FROM Tongyh_UserRoles08 ur
        JOIN Tongyh_Roles08 r ON ur.tyh_RoleId08 = r.tyh_RoleId08
        WHERE ur.tyh_Username08 = p_username;

        -- 记录登录日志
        INSERT INTO Tongyh_OperationLogs08 (tyh_Username08, tyh_Operation08, tyh_Details08, tyh_Timestamp08)
        VALUES (p_username, '用户登录', p_username || ' 登录成功', CURRENT_TIMESTAMP);

        RETURN QUERY SELECT TRUE, '登录成功', v_rec.tyh_Eno08, v_roles;
    ELSE
        -- 登录失败
        UPDATE Tongyh_Uspa08
        SET tyh_FailedAttempts08 = tyh_FailedAttempts08 + 1,
            tyh_LockTime08 = CASE
                WHEN tyh_FailedAttempts08 + 1 >= 5
                THEN CURRENT_TIMESTAMP + INTERVAL '30 minutes'
                ELSE tyh_LockTime08
            END
        WHERE tyh_Username08 = p_username;

        BEGIN
            SELECT tyh_FailedAttempts08 INTO STRICT v_rec.tyh_FailedAttempts08
            FROM Tongyh_Uspa08 WHERE tyh_Username08 = p_username;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_rec.tyh_FailedAttempts08 := 0;
        END;

        INSERT INTO Tongyh_OperationLogs08 (tyh_Username08, tyh_Operation08, tyh_Details08, tyh_Timestamp08)
        VALUES (p_username, '登录失败',
                p_username || ' 登录失败（第' || v_rec.tyh_FailedAttempts08 || '次）', CURRENT_TIMESTAMP);

        RETURN QUERY SELECT FALSE,
            '密码错误（第' || v_rec.tyh_FailedAttempts08 || '次，5次将锁定30分钟）',
            NULL::VARCHAR, NULL::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- ★ 存储过程 2：计算并生成员工月度工资
--    根据基础工资标准 + 工资明细 + 专项扣除 → 实发工资
--    写入 Tongyh_Gz08 表
-- ============================================================
CREATE OR REPLACE FUNCTION fn_tyh_CalcSalary08(
    p_eno    VARCHAR,
    p_year   INT,
    p_months INT
)
RETURNS TABLE(
    tyh_Success08  BOOLEAN,
    tyh_Message08  TEXT,
    tyh_Gross08    NUMERIC,
    tyh_Tax08      NUMERIC,
    tyh_Special08  NUMERIC,
    tyh_Net08      NUMERIC
) AS $$
DECLARE
    v_emp       Tongyh_Emp08%ROWTYPE;
    v_wages     Tongyh_Wages08%ROWTYPE;
    v_detail    Tongyh_SalaryDetail08%ROWTYPE;
    v_special   Tongyh_Special08%ROWTYPE;
    v_gross     NUMERIC := 0;
    v_tax       NUMERIC := 0;
    v_spec_mon  NUMERIC := 0;
    v_net       NUMERIC := 0;
    v_daily     NUMERIC;
    v_abs_days  INT;
BEGIN
    -- 1. 获取员工信息
    BEGIN
        SELECT * INTO STRICT v_emp FROM Tongyh_Emp08 WHERE tyh_Eno08 = p_eno;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN QUERY SELECT FALSE, '员工 ' || p_eno || ' 不存在', NULL::NUMERIC, NULL::NUMERIC, NULL::NUMERIC, NULL::NUMERIC;
            RETURN;
    END;

    -- 2. 获取基础工资标准
    BEGIN
        SELECT * INTO STRICT v_wages FROM Tongyh_Wages08
        WHERE tyh_Dno08 = v_emp.tyh_Dno08
          AND tyh_Position08 = v_emp.tyh_Position08
          AND tyh_Level08 = v_emp.tyh_Level08;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN QUERY SELECT FALSE, '未找到基础工资标准（部门：' || v_emp.tyh_Dno08
                || '，职位：' || v_emp.tyh_Position08 || '，职级：' || v_emp.tyh_Level08 || '）',
                NULL::NUMERIC, NULL::NUMERIC, NULL::NUMERIC, NULL::NUMERIC;
            RETURN;
    END;

    -- 3. 获取工资明细
    BEGIN
        SELECT * INTO STRICT v_detail FROM Tongyh_SalaryDetail08
        WHERE tyh_Eno08 = p_eno AND tyh_Year08 = p_year AND tyh_Months08 = p_months;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN QUERY SELECT FALSE, p_eno || ' 在 ' || p_year || '年' || p_months || '月缺少工资明细',
                NULL::NUMERIC, NULL::NUMERIC, NULL::NUMERIC, NULL::NUMERIC;
            RETURN;
    END;

    -- 4. 获取专项附加扣除（可选，可能不存在）
    BEGIN
        SELECT * INTO STRICT v_special FROM Tongyh_Special08
        WHERE tyh_Eno08 = p_eno AND tyh_Year08 = p_year;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- 无专项扣除记录，使用默认空值
            v_special := NULL;
    END;

    -- 5. 计算收入
    v_daily := v_wages.tyh_Basics08 / NULLIF(v_detail.tyh_Wday08, 0);
    v_abs_days := v_detail.tyh_Wday08 - v_detail.tyh_Sj08;

    v_gross := v_wages.tyh_Basics08
             + v_wages.tyh_Extra08
             + v_wages.tyh_Riceextra08
             + v_wages.tyh_Trafficextra08
             + v_detail.tyh_Jiaban08
             + v_detail.tyh_Allday08
             - v_detail.tyh_AbsenceDeduction08
             - v_detail.tyh_OtherDeduction08;

    IF v_abs_days > 0 THEN
        v_gross := v_gross - (v_daily * v_abs_days);
    END IF;
    v_gross := GREATEST(v_gross, 0);

    -- 6. 专项月均摊
    IF v_special IS NOT NULL THEN
        v_spec_mon := ROUND((COALESCE(v_special.tyh_ChildEdu08,0)
                           + COALESCE(v_special.tyh_ContinueEdu08,0)
                           + COALESCE(v_special.tyh_MedicalTreat08,0)
                           + COALESCE(v_special.tyh_HouseLoans08,0)
                           + COALESCE(v_special.tyh_HouseRent08,0)
                           + COALESCE(v_special.tyh_SupportElderly08,0)
                           + COALESCE(v_special.tyh_ChildCare08,0)) / 12.0, 2);
    END IF;

    -- 7. 计算个税
    v_tax := fn_tyh_CalcTax08(v_gross, v_wages.tyh_Shebao08, v_wages.tyh_Gjj08, v_spec_mon);

    -- 8. 实发工资
    v_net := v_gross - v_wages.tyh_Shebao08 - v_wages.tyh_Gjj08 - v_tax;
    v_net := GREATEST(v_net, 0);

    -- 9. 写入工资表（若已存在则更新）
    IF EXISTS (SELECT 1 FROM Tongyh_Gz08
               WHERE tyh_Eno08 = p_eno AND tyh_Year08 = p_year AND tyh_Months08 = p_months) THEN
        UPDATE Tongyh_Gz08 SET
            tyh_Dno08 = v_emp.tyh_Dno08,
            tyh_Position08 = v_emp.tyh_Position08,
            tyh_Level08 = v_emp.tyh_Level08,
            tyh_Sf08 = v_net,
            tyh_Ks08 = v_tax,
            tyh_ExtraCost08 = v_spec_mon
        WHERE tyh_Eno08 = p_eno AND tyh_Year08 = p_year AND tyh_Months08 = p_months;
    ELSE
        INSERT INTO Tongyh_Gz08 (tyh_Eno08, tyh_Year08, tyh_Months08, tyh_Dno08,
            tyh_Position08, tyh_Level08, tyh_Sf08, tyh_Ks08, tyh_ExtraCost08)
        VALUES (p_eno, p_year, p_months, v_emp.tyh_Dno08,
            v_emp.tyh_Position08, v_emp.tyh_Level08, v_net, v_tax, v_spec_mon);
    END IF;

    RETURN QUERY SELECT TRUE,
        p_eno || ' ' || v_emp.tyh_Ename08 || ' ' || p_year || '年' || p_months || '月 工资计算完成',
        v_gross, v_tax, v_spec_mon, v_net;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- 完成
-- ============================================================
DO $$
BEGIN
    RAISE NOTICE '全部函数/存储过程创建完成！（5个）';
    RAISE NOTICE '  fn_tyh_HashPwd08     — 密码哈希';
    RAISE NOTICE '  fn_tyh_CheckPwd08    — 密码复杂度校验';
    RAISE NOTICE '  fn_tyh_CalcTax08     — 个税计算';
    RAISE NOTICE '★ fn_tyh_UserLogin08  — 用户登录认证（存储过程1）';
    RAISE NOTICE '★ fn_tyh_CalcSalary08 — 工资计算生成（存储过程2）';
END $$;
