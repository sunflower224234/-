-- ============================================================
-- 公司工资管理系统 - 基本表创建脚本
-- 数据库：TongyhMIS08 (openGauss)
-- 命名规范：表名 Tongyh_<表名>08，列名 tyh_<列名>08
-- ============================================================

-- ============================================================
-- 1. 部门表 (Tongyh_Depts08)
-- ============================================================
CREATE TABLE Tongyh_Depts08 (
    tyh_Dno08       VARCHAR(10)     NOT NULL,
    tyh_Dname08     VARCHAR(15)     NOT NULL,
    tyh_Downer08    VARCHAR(15)     NOT NULL,
    CONSTRAINT pk_Tongyh_Depts08 PRIMARY KEY (tyh_Dno08),
    CONSTRAINT uk_Tongyh_Depts08_dname UNIQUE (tyh_Dname08)
);

COMMENT ON TABLE  Tongyh_Depts08              IS '部门信息表';
COMMENT ON COLUMN Tongyh_Depts08.tyh_Dno08    IS '部门编号（主键）';
COMMENT ON COLUMN Tongyh_Depts08.tyh_Dname08  IS '部门名称（唯一）';
COMMENT ON COLUMN Tongyh_Depts08.tyh_Downer08 IS '部门主管姓名';

-- ============================================================
-- 2. 员工表 (Tongyh_Emp08)
-- ============================================================
CREATE TABLE Tongyh_Emp08 (
    tyh_Eno08               VARCHAR(10)     NOT NULL,
    tyh_Dno08               VARCHAR(10)     NOT NULL,
    tyh_Ename08             VARCHAR(15)     NOT NULL,
    tyh_Position08          VARCHAR(50)     NOT NULL,
    tyh_Level08             VARCHAR(2)      NOT NULL,
    tyh_IdCardNumber08      VARCHAR(20)     NOT NULL,
    tyh_PhoneNumber08       VARCHAR(15)     NOT NULL,
    tyh_Email08             VARCHAR(50)     NOT NULL,
    tyh_Address08           VARCHAR(100)    NOT NULL,
    CONSTRAINT pk_Tongyh_Emp08 PRIMARY KEY (tyh_Eno08),
    CONSTRAINT uk_Tongyh_Emp08_idcard  UNIQUE (tyh_IdCardNumber08),
    CONSTRAINT uk_Tongyh_Emp08_email   UNIQUE (tyh_Email08),
    CONSTRAINT ck_Tongyh_Emp08_level   CHECK (tyh_Level08 IN ('P1', 'P2', 'P3', 'P4')),
    CONSTRAINT fk_Tongyh_Emp08_dno     FOREIGN KEY (tyh_Dno08) REFERENCES Tongyh_Depts08(tyh_Dno08)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

COMMENT ON TABLE  Tongyh_Emp08                     IS '员工信息表';
COMMENT ON COLUMN Tongyh_Emp08.tyh_Eno08           IS '员工编号（主键）';
COMMENT ON COLUMN Tongyh_Emp08.tyh_Dno08           IS '部门编号（外键→Tongyh_Depts08）';
COMMENT ON COLUMN Tongyh_Emp08.tyh_Ename08         IS '员工姓名';
COMMENT ON COLUMN Tongyh_Emp08.tyh_Position08      IS '职位名称';
COMMENT ON COLUMN Tongyh_Emp08.tyh_Level08         IS '职级（P1/P2/P3/P4）';
COMMENT ON COLUMN Tongyh_Emp08.tyh_IdCardNumber08  IS '身份证号码（唯一）';
COMMENT ON COLUMN Tongyh_Emp08.tyh_PhoneNumber08   IS '电话号码';
COMMENT ON COLUMN Tongyh_Emp08.tyh_Email08         IS '电子邮箱（唯一）';
COMMENT ON COLUMN Tongyh_Emp08.tyh_Address08       IS '联系地址';

-- ============================================================
-- 3. 基础工资标准表 (Tongyh_Wages08)
-- ============================================================
CREATE TABLE Tongyh_Wages08 (
    tyh_Dno08           VARCHAR(10)     NOT NULL,
    tyh_Position08      VARCHAR(50)     NOT NULL,
    tyh_Level08         VARCHAR(2)      NOT NULL,
    tyh_Basics08        NUMERIC(10,2)   NOT NULL,
    tyh_Extra08         NUMERIC(10,2)   NOT NULL,
    tyh_Gjj08           NUMERIC(10,2)   NOT NULL,
    tyh_Shebao08        NUMERIC(10,2)   NOT NULL,
    tyh_Riceextra08     NUMERIC(10,2)   NOT NULL,
    tyh_Trafficextra08  NUMERIC(10,2)   NOT NULL,
    CONSTRAINT pk_Tongyh_Wages08 PRIMARY KEY (tyh_Dno08, tyh_Position08, tyh_Level08),
    CONSTRAINT ck_Tongyh_Wages08_level     CHECK (tyh_Level08 IN ('P1', 'P2', 'P3', 'P4')),
    CONSTRAINT ck_Tongyh_Wages08_basics    CHECK (tyh_Basics08 >= 0),
    CONSTRAINT ck_Tongyh_Wages08_extra     CHECK (tyh_Extra08 >= 0),
    CONSTRAINT ck_Tongyh_Wages08_gjj       CHECK (tyh_Gjj08 >= 0),
    CONSTRAINT ck_Tongyh_Wages08_shebao    CHECK (tyh_Shebao08 >= 0),
    CONSTRAINT ck_Tongyh_Wages08_rice      CHECK (tyh_Riceextra08 >= 0),
    CONSTRAINT ck_Tongyh_Wages08_traffic   CHECK (tyh_Trafficextra08 >= 0),
    CONSTRAINT fk_Tongyh_Wages08_dno       FOREIGN KEY (tyh_Dno08) REFERENCES Tongyh_Depts08(tyh_Dno08)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

COMMENT ON TABLE  Tongyh_Wages08                  IS '基础工资标准表';
COMMENT ON COLUMN Tongyh_Wages08.tyh_Dno08        IS '部门编号（主键之一）';
COMMENT ON COLUMN Tongyh_Wages08.tyh_Position08   IS '职位名称（主键之一）';
COMMENT ON COLUMN Tongyh_Wages08.tyh_Level08      IS '职级（主键之一，P1-P4）';
COMMENT ON COLUMN Tongyh_Wages08.tyh_Basics08     IS '基础工资金额';
COMMENT ON COLUMN Tongyh_Wages08.tyh_Extra08      IS '工资津贴';
COMMENT ON COLUMN Tongyh_Wages08.tyh_Gjj08        IS '公积金';
COMMENT ON COLUMN Tongyh_Wages08.tyh_Shebao08     IS '社保';
COMMENT ON COLUMN Tongyh_Wages08.tyh_Riceextra08  IS '餐费补贴';
COMMENT ON COLUMN Tongyh_Wages08.tyh_Trafficextra08 IS '通勤补贴';

-- ============================================================
-- 4. 工资明细表 (Tongyh_SalaryDetail08)
-- ============================================================
CREATE TABLE Tongyh_SalaryDetail08 (
    tyh_Eno08               VARCHAR(10)     NOT NULL,
    tyh_Year08              INT             NOT NULL,
    tyh_Months08            INT             NOT NULL,
    tyh_Wday08              INT             NOT NULL,
    tyh_Sj08                INT             NOT NULL,
    tyh_Cd08                INT             NOT NULL,
    tyh_Jiaban08            NUMERIC(10,2)   NOT NULL,
    tyh_Allday08            NUMERIC(10,2)   NOT NULL,
    tyh_AbsenceDeduction08  NUMERIC(10,2)   NOT NULL,
    tyh_OtherDeduction08    NUMERIC(10,2)   NOT NULL,
    CONSTRAINT pk_Tongyh_SalaryDetail08 PRIMARY KEY (tyh_Eno08, tyh_Year08, tyh_Months08),
    CONSTRAINT ck_Tongyh_SD08_months     CHECK (tyh_Months08 BETWEEN 1 AND 12),
    CONSTRAINT ck_Tongyh_SD08_year       CHECK (tyh_Year08 >= 2000 AND tyh_Year08 <= 2100),
    CONSTRAINT ck_Tongyh_SD08_wday       CHECK (tyh_Wday08 > 0),
    CONSTRAINT ck_Tongyh_SD08_sj         CHECK (tyh_Sj08 >= 0 AND tyh_Sj08 <= tyh_Wday08),
    CONSTRAINT ck_Tongyh_SD08_cd         CHECK (tyh_Cd08 >= 0),
    CONSTRAINT ck_Tongyh_SD08_jiaban     CHECK (tyh_Jiaban08 >= 0),
    CONSTRAINT ck_Tongyh_SD08_allday     CHECK (tyh_Allday08 >= 0),
    CONSTRAINT ck_Tongyh_SD08_absence    CHECK (tyh_AbsenceDeduction08 >= 0),
    CONSTRAINT ck_Tongyh_SD08_other      CHECK (tyh_OtherDeduction08 >= 0),
    CONSTRAINT fk_Tongyh_SD08_eno        FOREIGN KEY (tyh_Eno08) REFERENCES Tongyh_Emp08(tyh_Eno08)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

COMMENT ON TABLE  Tongyh_SalaryDetail08                    IS '工资明细表';
COMMENT ON COLUMN Tongyh_SalaryDetail08.tyh_Eno08          IS '员工编号（主键之一）';
COMMENT ON COLUMN Tongyh_SalaryDetail08.tyh_Year08         IS '年份（主键之一）';
COMMENT ON COLUMN Tongyh_SalaryDetail08.tyh_Months08       IS '月份（主键之一，1-12）';
COMMENT ON COLUMN Tongyh_SalaryDetail08.tyh_Wday08         IS '计划工作天数';
COMMENT ON COLUMN Tongyh_SalaryDetail08.tyh_Sj08           IS '实际工作天数（≤计划天数）';
COMMENT ON COLUMN Tongyh_SalaryDetail08.tyh_Cd08           IS '迟到天数';
COMMENT ON COLUMN Tongyh_SalaryDetail08.tyh_Jiaban08       IS '加班工资金额';
COMMENT ON COLUMN Tongyh_SalaryDetail08.tyh_Allday08       IS '全勤奖励金额';
COMMENT ON COLUMN Tongyh_SalaryDetail08.tyh_AbsenceDeduction08 IS '缺勤扣款金额';
COMMENT ON COLUMN Tongyh_SalaryDetail08.tyh_OtherDeduction08   IS '其他扣款金额';

-- ============================================================
-- 5. 工资表 (Tongyh_Gz08)
-- ============================================================
CREATE TABLE Tongyh_Gz08 (
    tyh_Eno08           VARCHAR(10)     NOT NULL,
    tyh_Year08          INT             NOT NULL,
    tyh_Months08        INT             NOT NULL,
    tyh_Dno08           VARCHAR(10)     NOT NULL,
    tyh_Position08      VARCHAR(50)     NOT NULL,
    tyh_Level08         VARCHAR(2)      NOT NULL,
    tyh_Sf08            NUMERIC(10,2)   NOT NULL,
    tyh_Ks08            NUMERIC(10,2)   NOT NULL,
    tyh_ExtraCost08     NUMERIC(10,2)   NOT NULL,
    CONSTRAINT pk_Tongyh_Gz08 PRIMARY KEY (tyh_Eno08, tyh_Year08, tyh_Months08),
    CONSTRAINT ck_Tongyh_Gz08_months     CHECK (tyh_Months08 BETWEEN 1 AND 12),
    CONSTRAINT ck_Tongyh_Gz08_year       CHECK (tyh_Year08 >= 2000 AND tyh_Year08 <= 2100),
    CONSTRAINT ck_Tongyh_Gz08_sf         CHECK (tyh_Sf08 >= 0),
    CONSTRAINT ck_Tongyh_Gz08_ks         CHECK (tyh_Ks08 >= 0),
    CONSTRAINT ck_Tongyh_Gz08_extracost  CHECK (tyh_ExtraCost08 >= 0),
    CONSTRAINT ck_Tongyh_Gz08_level      CHECK (tyh_Level08 IN ('P1', 'P2', 'P3', 'P4')),
    CONSTRAINT fk_Tongyh_Gz08_eno        FOREIGN KEY (tyh_Eno08) REFERENCES Tongyh_Emp08(tyh_Eno08)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_Tongyh_Gz08_dno        FOREIGN KEY (tyh_Dno08) REFERENCES Tongyh_Depts08(tyh_Dno08)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

COMMENT ON TABLE  Tongyh_Gz08                  IS '工资表（每月计算结果）';
COMMENT ON COLUMN Tongyh_Gz08.tyh_Eno08        IS '员工编号（主键之一）';
COMMENT ON COLUMN Tongyh_Gz08.tyh_Year08       IS '年份（主键之一）';
COMMENT ON COLUMN Tongyh_Gz08.tyh_Months08     IS '月份（主键之一，1-12）';
COMMENT ON COLUMN Tongyh_Gz08.tyh_Dno08        IS '部门编号';
COMMENT ON COLUMN Tongyh_Gz08.tyh_Position08   IS '职位名称（历史快照）';
COMMENT ON COLUMN Tongyh_Gz08.tyh_Level08      IS '职级（历史快照）';
COMMENT ON COLUMN Tongyh_Gz08.tyh_Sf08         IS '实发工资金额';
COMMENT ON COLUMN Tongyh_Gz08.tyh_Ks08         IS '扣税金额';
COMMENT ON COLUMN Tongyh_Gz08.tyh_ExtraCost08  IS '专项附加扣除月均摊金额';

-- ============================================================
-- 6. 专项附加扣除表 (Tongyh_Special08)
-- ============================================================
CREATE TABLE Tongyh_Special08 (
    tyh_Sno08               VARCHAR(15)     NOT NULL,
    tyh_Eno08               VARCHAR(10)     NOT NULL,
    tyh_Year08              INT             NOT NULL,
    tyh_ChildEdu08          NUMERIC(10,2)   DEFAULT 0,
    tyh_ContinueEdu08       NUMERIC(10,2)   DEFAULT 0,
    tyh_MedicalTreat08      NUMERIC(10,2)   DEFAULT 0,
    tyh_HouseLoans08        NUMERIC(10,2)   DEFAULT 0,
    tyh_HouseRent08         NUMERIC(10,2)   DEFAULT 0,
    tyh_SupportElderly08    NUMERIC(10,2)   DEFAULT 0,
    tyh_ChildCare08         NUMERIC(10,2)   DEFAULT 0,
    CONSTRAINT pk_Tongyh_Special08 PRIMARY KEY (tyh_Sno08),
    CONSTRAINT ck_Tongyh_Special08_year    CHECK (tyh_Year08 >= 2000 AND tyh_Year08 <= 2100),
    CONSTRAINT ck_Tongyh_Special08_childedu    CHECK (tyh_ChildEdu08 >= 0),
    CONSTRAINT ck_Tongyh_Special08_continuedu  CHECK (tyh_ContinueEdu08 >= 0),
    CONSTRAINT ck_Tongyh_Special08_medical     CHECK (tyh_MedicalTreat08 >= 0),
    CONSTRAINT ck_Tongyh_Special08_houseloans  CHECK (tyh_HouseLoans08 >= 0),
    CONSTRAINT ck_Tongyh_Special08_houserent   CHECK (tyh_HouseRent08 >= 0),
    CONSTRAINT ck_Tongyh_Special08_elderly     CHECK (tyh_SupportElderly08 >= 0),
    CONSTRAINT ck_Tongyh_Special08_childcare   CHECK (tyh_ChildCare08 >= 0),
    CONSTRAINT fk_Tongyh_Special08_eno FOREIGN KEY (tyh_Eno08) REFERENCES Tongyh_Emp08(tyh_Eno08)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

COMMENT ON TABLE  Tongyh_Special08                    IS '专项附加扣除表（七项个税专项扣除）';
COMMENT ON COLUMN Tongyh_Special08.tyh_Sno08          IS '专项扣除编号（主键）';
COMMENT ON COLUMN Tongyh_Special08.tyh_Eno08          IS '员工编号（外键）';
COMMENT ON COLUMN Tongyh_Special08.tyh_Year08         IS '填报年份';
COMMENT ON COLUMN Tongyh_Special08.tyh_ChildEdu08     IS '子女教育专项扣除金额';
COMMENT ON COLUMN Tongyh_Special08.tyh_ContinueEdu08  IS '继续教育专项扣除金额';
COMMENT ON COLUMN Tongyh_Special08.tyh_MedicalTreat08 IS '大病医疗专项扣除金额';
COMMENT ON COLUMN Tongyh_Special08.tyh_HouseLoans08   IS '住房贷款利息专项扣除金额';
COMMENT ON COLUMN Tongyh_Special08.tyh_HouseRent08    IS '住房租金专项扣除金额';
COMMENT ON COLUMN Tongyh_Special08.tyh_SupportElderly08 IS '赡养老人专项扣除金额';
COMMENT ON COLUMN Tongyh_Special08.tyh_ChildCare08    IS '婴幼儿照护专项扣除金额';

-- ============================================================
-- 7. 家属关系表 (Tongyh_Relations08)
-- ============================================================
CREATE TABLE Tongyh_Relations08 (
    tyh_IdNumber08      VARCHAR(255)    NOT NULL,
    tyh_Eno08           VARCHAR(10)     NOT NULL,
    tyh_Jname08         VARCHAR(15)     NOT NULL,
    tyh_Relationship08  VARCHAR(20)     NOT NULL,
    CONSTRAINT pk_Tongyh_Relations08 PRIMARY KEY (tyh_IdNumber08),
    CONSTRAINT fk_Tongyh_Relations08_eno FOREIGN KEY (tyh_Eno08) REFERENCES Tongyh_Emp08(tyh_Eno08)
        ON UPDATE CASCADE ON DELETE CASCADE
);

COMMENT ON TABLE  Tongyh_Relations08                   IS '家属关系表';
COMMENT ON COLUMN Tongyh_Relations08.tyh_IdNumber08    IS '家属身份证号（主键）';
COMMENT ON COLUMN Tongyh_Relations08.tyh_Eno08         IS '员工编号（外键）';
COMMENT ON COLUMN Tongyh_Relations08.tyh_Jname08       IS '家属姓名';
COMMENT ON COLUMN Tongyh_Relations08.tyh_Relationship08 IS '与员工的关系';

-- ============================================================
-- 8. 角色表 (Tongyh_Roles08)
-- ============================================================
CREATE TABLE Tongyh_Roles08 (
    tyh_RoleId08        INT             NOT NULL,
    tyh_RoleName08      VARCHAR(50)     NOT NULL,
    CONSTRAINT pk_Tongyh_Roles08 PRIMARY KEY (tyh_RoleId08),
    CONSTRAINT uk_Tongyh_Roles08_name UNIQUE (tyh_RoleName08)
);

COMMENT ON TABLE  Tongyh_Roles08                IS '角色表';
COMMENT ON COLUMN Tongyh_Roles08.tyh_RoleId08   IS '角色编号（主键）';
COMMENT ON COLUMN Tongyh_Roles08.tyh_RoleName08 IS '角色名称（唯一）';

-- ============================================================
-- 9. 用户密码表 (Tongyh_Uspa08)
-- ============================================================
CREATE TABLE Tongyh_Uspa08 (
    tyh_Username08              VARCHAR(255)    NOT NULL,
    tyh_Eno08                   VARCHAR(10),
    tyh_Password08              VARCHAR(255)    NOT NULL,
    tyh_Encryptedpassword08     VARCHAR(255)    NOT NULL,
    tyh_LastPasswordChange08    TIMESTAMP       NOT NULL,
    tyh_FailedAttempts08        INT             NOT NULL DEFAULT 0,
    tyh_LockTime08              TIMESTAMP,
    CONSTRAINT pk_Tongyh_Uspa08 PRIMARY KEY (tyh_Username08),
    CONSTRAINT ck_Tongyh_Uspa08_failed CHECK (tyh_FailedAttempts08 >= 0),
    CONSTRAINT fk_Tongyh_Uspa08_eno FOREIGN KEY (tyh_Eno08) REFERENCES Tongyh_Emp08(tyh_Eno08)
        ON UPDATE CASCADE ON DELETE SET NULL
);

COMMENT ON TABLE  Tongyh_Uspa08                           IS '用户密码表';
COMMENT ON COLUMN Tongyh_Uspa08.tyh_Username08            IS '用户名（主键）';
COMMENT ON COLUMN Tongyh_Uspa08.tyh_Eno08                 IS '关联员工编号';
COMMENT ON COLUMN Tongyh_Uspa08.tyh_Password08            IS '明文密码（初始设置用）';
COMMENT ON COLUMN Tongyh_Uspa08.tyh_Encryptedpassword08   IS 'SM3加密后的密码摘要';
COMMENT ON COLUMN Tongyh_Uspa08.tyh_LastPasswordChange08  IS '上次密码修改时间';
COMMENT ON COLUMN Tongyh_Uspa08.tyh_FailedAttempts08      IS '连续登录失败次数';
COMMENT ON COLUMN Tongyh_Uspa08.tyh_LockTime08            IS '账户锁定时间';

-- ============================================================
-- 10. 用户角色表 (Tongyh_UserRoles08)
-- ============================================================
CREATE TABLE Tongyh_UserRoles08 (
    tyh_Username08      VARCHAR(255)    NOT NULL,
    tyh_RoleId08        INT             NOT NULL,
    CONSTRAINT pk_Tongyh_UserRoles08 PRIMARY KEY (tyh_Username08, tyh_RoleId08),
    CONSTRAINT fk_Tongyh_UR08_username FOREIGN KEY (tyh_Username08) REFERENCES Tongyh_Uspa08(tyh_Username08)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_Tongyh_UR08_roleid   FOREIGN KEY (tyh_RoleId08)  REFERENCES Tongyh_Roles08(tyh_RoleId08)
        ON UPDATE CASCADE ON DELETE CASCADE
);

COMMENT ON TABLE  Tongyh_UserRoles08                IS '用户角色关联表';
COMMENT ON COLUMN Tongyh_UserRoles08.tyh_Username08 IS '用户名（主键之一）';
COMMENT ON COLUMN Tongyh_UserRoles08.tyh_RoleId08   IS '角色编号（主键之一）';

-- ============================================================
-- 11. 操作日志表 (Tongyh_OperationLogs08)
-- ============================================================
CREATE TABLE Tongyh_OperationLogs08 (
    tyh_LogId08         SERIAL          NOT NULL,
    tyh_Username08      VARCHAR(255),
    tyh_Operation08     VARCHAR(255)    NOT NULL,
    tyh_Details08       TEXT            NOT NULL,
    tyh_Timestamp08     TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_Tongyh_OperationLogs08 PRIMARY KEY (tyh_LogId08),
    CONSTRAINT fk_Tongyh_OL08_username FOREIGN KEY (tyh_Username08) REFERENCES Tongyh_Uspa08(tyh_Username08)
        ON UPDATE CASCADE ON DELETE SET NULL
);

COMMENT ON TABLE  Tongyh_OperationLogs08                  IS '操作日志表（安全审计）';
COMMENT ON COLUMN Tongyh_OperationLogs08.tyh_LogId08      IS '日志编号（主键，自增）';
COMMENT ON COLUMN Tongyh_OperationLogs08.tyh_Username08   IS '操作用户名';
COMMENT ON COLUMN Tongyh_OperationLogs08.tyh_Operation08  IS '操作类型';
COMMENT ON COLUMN Tongyh_OperationLogs08.tyh_Details08    IS '操作详细描述';
COMMENT ON COLUMN Tongyh_OperationLogs08.tyh_Timestamp08  IS '操作时间戳';

-- ============================================================
-- 完成
-- ============================================================
DO $$
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE '11张基本表创建完成！（Tongyh_前缀命名）';
    RAISE NOTICE '============================================';
END $$;
