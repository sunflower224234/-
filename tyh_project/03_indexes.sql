-- ============================================================
-- 公司工资管理系统 - 索引创建脚本
-- 数据库：TongyhMIS08 (openGauss)
-- 命名规范：索引名 idx_tyh_<描述>08
-- ============================================================
CREATE INDEX idx_tyh_emp_dno08        ON Tongyh_Emp08 (tyh_Dno08);
CREATE UNIQUE INDEX uk_tyh_emp_eno08  ON Tongyh_Emp08 (tyh_Eno08);
CREATE UNIQUE INDEX uk_tyh_emp_email08 ON Tongyh_Emp08 (tyh_Email08);
CREATE UNIQUE INDEX uk_tyh_emp_idcard08 ON Tongyh_Emp08 (tyh_IdCardNumber08);
CREATE INDEX idx_tyh_emp_ename08      ON Tongyh_Emp08 (tyh_Ename08);
CREATE INDEX idx_tyh_emp_level08      ON Tongyh_Emp08 (tyh_Level08);
CREATE INDEX idx_tyh_wages_dno08           ON Tongyh_Wages08 (tyh_Dno08);
CREATE INDEX idx_tyh_wages_dno_pos_lvl08   ON Tongyh_Wages08 (tyh_Dno08, tyh_Position08, tyh_Level08);
CREATE INDEX idx_tyh_gz_eno_ym08    ON Tongyh_Gz08 (tyh_Eno08, tyh_Year08, tyh_Months08);
CREATE INDEX idx_tyh_gz_dno_ym08    ON Tongyh_Gz08 (tyh_Dno08, tyh_Year08, tyh_Months08);
CREATE INDEX idx_tyh_gz_year_mon08  ON Tongyh_Gz08 (tyh_Year08, tyh_Months08);
CREATE INDEX idx_tyh_gz_level08     ON Tongyh_Gz08 (tyh_Level08);
CREATE INDEX idx_tyh_sd_eno_ym08 ON Tongyh_SalaryDetail08 (tyh_Eno08, tyh_Year08, tyh_Months08);
CREATE INDEX idx_tyh_sp_eno_year08 ON Tongyh_Special08 (tyh_Eno08, tyh_Year08);
CREATE INDEX idx_tyh_uspa_username08 ON Tongyh_Uspa08 (tyh_Username08);
CREATE INDEX idx_tyh_uspa_eno08      ON Tongyh_Uspa08 (tyh_Eno08);
CREATE INDEX idx_tyh_ur_user_role08  ON Tongyh_UserRoles08 (tyh_Username08, tyh_RoleId08);
CREATE INDEX idx_tyh_ur_roleid08     ON Tongyh_UserRoles08 (tyh_RoleId08);
CREATE INDEX idx_tyh_ur_username08   ON Tongyh_UserRoles08 (tyh_Username08);
CREATE INDEX idx_tyh_ol_timestamp08  ON Tongyh_OperationLogs08 (tyh_Timestamp08);
CREATE INDEX idx_tyh_ol_username08   ON Tongyh_OperationLogs08 (tyh_Username08);
CREATE INDEX idx_tyh_ol_operation08  ON Tongyh_OperationLogs08 (tyh_Operation08);
CREATE UNIQUE INDEX uk_tyh_depts_dname08 ON Tongyh_Depts08 (tyh_Dname08);
CREATE INDEX idx_tyh_rel_eno08 ON Tongyh_Relations08 (tyh_Eno08);
DO $$
BEGIN
    RAISE NOTICE '全部索引创建完成！（26个索引）';
END $$;
