-- ============================================================
-- 公司工资管理系统 - 视图创建脚本
-- 数据库：TongyhMIS08 (openGauss)
-- 命名规范：视图名 v_tyh_<名称>08
-- ============================================================

-- ----------------------------------------------------------
-- 1. 员工综合信息视图（含部门名称、敏感信息脱敏）
-- ----------------------------------------------------------
CREATE OR REPLACE VIEW v_tyh_EmpInfo08 AS
SELECT
    e.tyh_Eno08,
    e.tyh_Ename08,
    e.tyh_Dno08,
    d.tyh_Dname08,
    e.tyh_Position08,
    e.tyh_Level08,
    -- 身份证号脱敏：保留前6后4
    OVERLAY(e.tyh_IdCardNumber08  PLACING '**********' FROM 7 FOR 8) AS tyh_IdCardMasked08,
    -- 手机号脱敏：保留前3后4
    OVERLAY(e.tyh_PhoneNumber08   PLACING '****' FROM 4 FOR 4)       AS tyh_PhoneMasked08,
    e.tyh_Email08,
    e.tyh_Address08,
    d.tyh_Downer08 AS tyh_DeptManager08
FROM Tongyh_Emp08 e
LEFT JOIN Tongyh_Depts08 d ON e.tyh_Dno08 = d.tyh_Dno08;

-- ----------------------------------------------------------
-- 2. 月度工资综合视图（完整收入/扣除/出勤明细）
-- ----------------------------------------------------------
CREATE OR REPLACE VIEW v_tyh_SalaryFull08 AS
SELECT
    g.tyh_Eno08,
    e.tyh_Ename08,
    g.tyh_Year08,
    g.tyh_Months08,
    g.tyh_Dno08,
    d.tyh_Dname08,
    g.tyh_Position08,
    g.tyh_Level08,
    -- 收入项
    w.tyh_Basics08          AS tyh_BaseSalary08,
    w.tyh_Extra08           AS tyh_Allowance08,
    w.tyh_Riceextra08       AS tyh_MealSubsidy08,
    sd.tyh_Jiaban08         AS tyh_OvertimePay08,
    sd.tyh_Allday08         AS tyh_FullAttBonus08,
    w.tyh_Trafficextra08    AS tyh_CommuteSubsidy08,
    -- 扣除项
    w.tyh_Shebao08          AS tyh_SocialInsurance08,
    w.tyh_Gjj08             AS tyh_HousingFund08,
    sd.tyh_AbsenceDeduction08 AS tyh_AbsenceDeduct08,
    sd.tyh_OtherDeduction08   AS tyh_OtherDeduct08,
    g.tyh_Ks08              AS tyh_Tax08,
    g.tyh_ExtraCost08       AS tyh_SpecialMonthly08,
    -- 实发
    g.tyh_Sf08              AS tyh_NetSalary08,
    -- 出勤
    sd.tyh_Wday08,
    sd.tyh_Sj08,
    sd.tyh_Cd08
FROM Tongyh_Gz08 g
JOIN Tongyh_Emp08 e          ON g.tyh_Eno08 = e.tyh_Eno08
LEFT JOIN Tongyh_Depts08 d   ON g.tyh_Dno08 = d.tyh_Dno08
LEFT JOIN Tongyh_SalaryDetail08 sd ON g.tyh_Eno08 = sd.tyh_Eno08
    AND g.tyh_Year08 = sd.tyh_Year08 AND g.tyh_Months08 = sd.tyh_Months08
LEFT JOIN Tongyh_Wages08 w   ON g.tyh_Dno08 = w.tyh_Dno08
    AND g.tyh_Position08 = w.tyh_Position08 AND g.tyh_Level08 = w.tyh_Level08;

-- ----------------------------------------------------------
-- 3. 专项附加扣除年度汇总视图
-- ----------------------------------------------------------
CREATE OR REPLACE VIEW v_tyh_SpecialSummary08 AS
SELECT
    s.tyh_Eno08,
    e.tyh_Ename08,
    d.tyh_Dname08,
    s.tyh_Year08,
    s.tyh_ChildEdu08,
    s.tyh_ContinueEdu08,
    s.tyh_MedicalTreat08,
    s.tyh_HouseLoans08,
    s.tyh_HouseRent08,
    s.tyh_SupportElderly08,
    s.tyh_ChildCare08,
    (s.tyh_ChildEdu08 + s.tyh_ContinueEdu08 + s.tyh_MedicalTreat08
     + s.tyh_HouseLoans08 + s.tyh_HouseRent08 + s.tyh_SupportElderly08
     + s.tyh_ChildCare08) AS tyh_TotalSpecial08,
    ROUND((s.tyh_ChildEdu08 + s.tyh_ContinueEdu08 + s.tyh_MedicalTreat08
         + s.tyh_HouseLoans08 + s.tyh_HouseRent08 + s.tyh_SupportElderly08
         + s.tyh_ChildCare08) / 12.0, 2) AS tyh_MonthlyAvg08
FROM Tongyh_Special08 s
JOIN Tongyh_Emp08 e        ON s.tyh_Eno08 = e.tyh_Eno08
LEFT JOIN Tongyh_Depts08 d ON e.tyh_Dno08 = d.tyh_Dno08;

-- ----------------------------------------------------------
-- 4. 用户角色权限视图
-- ----------------------------------------------------------
CREATE OR REPLACE VIEW v_tyh_UserRoles08 AS
SELECT
    u.tyh_Username08,
    u.tyh_Eno08,
    e.tyh_Ename08,
    r.tyh_RoleId08,
    r.tyh_RoleName08,
    u.tyh_LastPasswordChange08,
    u.tyh_FailedAttempts08,
    u.tyh_LockTime08,
    CASE WHEN u.tyh_LockTime08 IS NOT NULL AND u.tyh_LockTime08 > CURRENT_TIMESTAMP
         THEN '已锁定' ELSE '正常' END AS tyh_AccountStatus08
FROM Tongyh_Uspa08 u
JOIN Tongyh_UserRoles08 ur ON u.tyh_Username08 = ur.tyh_Username08
JOIN Tongyh_Roles08 r      ON ur.tyh_RoleId08 = r.tyh_RoleId08
LEFT JOIN Tongyh_Emp08 e   ON u.tyh_Eno08 = e.tyh_Eno08;

-- ----------------------------------------------------------
-- 5. 审计日志视图（近180天）
-- ----------------------------------------------------------
CREATE OR REPLACE VIEW v_tyh_AuditLog08 AS
SELECT
    tyh_LogId08,
    tyh_Username08,
    tyh_Operation08,
    tyh_Details08,
    tyh_Timestamp08
FROM Tongyh_OperationLogs08
WHERE tyh_Timestamp08 >= CURRENT_TIMESTAMP - INTERVAL '180 days'
ORDER BY tyh_Timestamp08 DESC;

-- ----------------------------------------------------------
-- 6. 部门工资统计视图
-- ----------------------------------------------------------
CREATE OR REPLACE VIEW v_tyh_DeptSalaryStats08 AS
SELECT
    d.tyh_Dname08,
    g.tyh_Year08,
    g.tyh_Months08,
    COUNT(DISTINCT g.tyh_Eno08) AS tyh_EmpCount08,
    SUM(g.tyh_Sf08)              AS tyh_TotalNet08,
    ROUND(AVG(g.tyh_Sf08), 2)    AS tyh_AvgNet08,
    MAX(g.tyh_Sf08)              AS tyh_MaxNet08,
    MIN(g.tyh_Sf08)              AS tyh_MinNet08,
    SUM(g.tyh_Ks08)              AS tyh_TotalTax08
FROM Tongyh_Gz08 g
JOIN Tongyh_Depts08 d ON g.tyh_Dno08 = d.tyh_Dno08
GROUP BY d.tyh_Dname08, g.tyh_Year08, g.tyh_Months08
ORDER BY g.tyh_Year08 DESC, g.tyh_Months08 DESC, d.tyh_Dname08;

-- ----------------------------------------------------------
-- 完成
-- ----------------------------------------------------------
DO $$
BEGIN
    RAISE NOTICE '全部视图创建完成！（6个视图）';
END $$;
