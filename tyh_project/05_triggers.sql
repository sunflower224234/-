-- ============================================================
-- 公司工资管理系统 - 触发器脚本
-- 数据库：TongyhMIS08 (openGauss)
-- 命名规范：函数 fn_tyh_<名称>08，触发器 trg_tyh_<名称>08
-- 说明：共4个触发器 — 员工审计、工资审计、密码跟踪、登录解锁
-- ============================================================

-- ============================================================
-- 1. 员工表审计触发器（增删改自动记录日志）
-- ============================================================
CREATE OR REPLACE FUNCTION fn_tyh_LogEmpChanges08()
RETURNS TRIGGER AS $$
DECLARE
    v_username VARCHAR(255);
    v_op VARCHAR(255);
    v_detail TEXT;
BEGIN
    v_username := current_user;

    IF TG_OP = 'INSERT' THEN
        v_op := '新增员工';
        v_detail := '新增员工：' || NEW.tyh_Eno08 || ' ' || NEW.tyh_Ename08
                 || '，部门：' || NEW.tyh_Dno08 || '，职位：' || NEW.tyh_Position08
                 || '，职级：' || NEW.tyh_Level08;
    ELSIF TG_OP = 'UPDATE' THEN
        v_op := '修改员工信息';
        v_detail := '修改员工：' || NEW.tyh_Eno08 || ' ' || NEW.tyh_Ename08
                 || '，部门：' || COALESCE(OLD.tyh_Dno08,'') || '→' || COALESCE(NEW.tyh_Dno08,'')
                 || '，职级：' || COALESCE(OLD.tyh_Level08,'') || '→' || COALESCE(NEW.tyh_Level08,'');
    ELSIF TG_OP = 'DELETE' THEN
        v_op := '删除员工';
        v_detail := '删除员工：' || OLD.tyh_Eno08 || ' ' || OLD.tyh_Ename08;
    END IF;

    INSERT INTO Tongyh_OperationLogs08 (tyh_Username08, tyh_Operation08, tyh_Details08, tyh_Timestamp08)
    VALUES (v_username, v_op, v_detail, CURRENT_TIMESTAMP);

    RETURN NULL;
EXCEPTION WHEN OTHERS THEN
    -- Fallback: use NULL username if FK violation
    INSERT INTO Tongyh_OperationLogs08 (tyh_Username08, tyh_Operation08, tyh_Details08, tyh_Timestamp08)
    VALUES (NULL, v_op, v_detail, CURRENT_TIMESTAMP);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tyh_EmpAudit08
    AFTER INSERT OR UPDATE OR DELETE ON Tongyh_Emp08
    FOR EACH ROW EXECUTE PROCEDURE fn_tyh_LogEmpChanges08();

-- ============================================================
-- 2. 工资表审计触发器（增删改自动记录日志）
-- ============================================================
CREATE OR REPLACE FUNCTION fn_tyh_LogGzChanges08()
RETURNS TRIGGER AS $$
DECLARE
    v_username VARCHAR(255);
    v_op VARCHAR(255);
    v_detail TEXT;
BEGIN
    v_username := current_user;

    IF TG_OP = 'INSERT' THEN
        v_op := '生成工资';
        v_detail := '生成工资：' || NEW.tyh_Eno08 || '，' || NEW.tyh_Year08 || '年'
                 || NEW.tyh_Months08 || '月，实发：' || NEW.tyh_Sf08;
    ELSIF TG_OP = 'UPDATE' THEN
        v_op := '修改工资';
        v_detail := '修改工资：' || NEW.tyh_Eno08 || '，' || NEW.tyh_Year08 || '年'
                 || NEW.tyh_Months08 || '月，实发：' || OLD.tyh_Sf08 || '→' || NEW.tyh_Sf08;
    ELSIF TG_OP = 'DELETE' THEN
        v_op := '删除工资';
        v_detail := '删除工资：' || OLD.tyh_Eno08 || '，' || OLD.tyh_Year08 || '年'
                 || OLD.tyh_Months08 || '月';
    END IF;

    INSERT INTO Tongyh_OperationLogs08 (tyh_Username08, tyh_Operation08, tyh_Details08, tyh_Timestamp08)
    VALUES (v_username, v_op, v_detail, CURRENT_TIMESTAMP);

    RETURN NULL;
EXCEPTION WHEN OTHERS THEN
    INSERT INTO Tongyh_OperationLogs08 (tyh_Username08, tyh_Operation08, tyh_Details08, tyh_Timestamp08)
    VALUES (NULL, v_op, v_detail, CURRENT_TIMESTAMP);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tyh_GzAudit08
    AFTER INSERT OR UPDATE OR DELETE ON Tongyh_Gz08
    FOR EACH ROW EXECUTE PROCEDURE fn_tyh_LogGzChanges08();

-- ============================================================
-- 3. 密码修改跟踪触发器（自动更新最后修改时间）
-- ============================================================
CREATE OR REPLACE FUNCTION fn_tyh_PwdChangeTrack08()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.tyh_Encryptedpassword08 <> OLD.tyh_Encryptedpassword08 THEN
        NEW.tyh_LastPasswordChange08 := CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tyh_PwdChange08
    BEFORE UPDATE ON Tongyh_Uspa08
    FOR EACH ROW EXECUTE PROCEDURE fn_tyh_PwdChangeTrack08();

-- ============================================================
-- 4. 登录锁定自动解锁触发器
-- ============================================================
CREATE OR REPLACE FUNCTION fn_tyh_AutoUnlock08()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.tyh_LockTime08 IS NOT NULL AND NEW.tyh_LockTime08 <= CURRENT_TIMESTAMP THEN
        NEW.tyh_LockTime08 := NULL;
        NEW.tyh_FailedAttempts08 := 0;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tyh_AutoUnlock08
    BEFORE UPDATE ON Tongyh_Uspa08
    FOR EACH ROW EXECUTE PROCEDURE fn_tyh_AutoUnlock08();

-- ============================================================
-- 完成
-- ============================================================
DO $$
BEGIN
    RAISE NOTICE 'triggers created: 4 (EmpAudit, GzAudit, PwdChange, AutoUnlock)';
END $$;
