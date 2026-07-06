-- ============================================================
-- 公司工资管理系统 - 部署验证脚本
-- ============================================================

\echo '============================================'
\echo '  部署验证报告'
\echo '============================================'

\echo ''
\echo '--- 1. 基本表 ---'
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
ORDER BY table_name;

\echo ''
\echo '--- 2. 数据统计 ---'
SELECT 'Tongyh_Depts08'           AS 表名, COUNT(*) AS 记录数 FROM Tongyh_Depts08
UNION ALL SELECT 'Tongyh_Emp08',            COUNT(*) FROM Tongyh_Emp08
UNION ALL SELECT 'Tongyh_Wages08',          COUNT(*) FROM Tongyh_Wages08
UNION ALL SELECT 'Tongyh_SalaryDetail08',   COUNT(*) FROM Tongyh_SalaryDetail08
UNION ALL SELECT 'Tongyh_Gz08',             COUNT(*) FROM Tongyh_Gz08
UNION ALL SELECT 'Tongyh_Special08',        COUNT(*) FROM Tongyh_Special08
UNION ALL SELECT 'Tongyh_Relations08',      COUNT(*) FROM Tongyh_Relations08
UNION ALL SELECT 'Tongyh_Roles08',          COUNT(*) FROM Tongyh_Roles08
UNION ALL SELECT 'Tongyh_Uspa08',           COUNT(*) FROM Tongyh_Uspa08
UNION ALL SELECT 'Tongyh_UserRoles08',      COUNT(*) FROM Tongyh_UserRoles08
UNION ALL SELECT 'Tongyh_OperationLogs08',  COUNT(*) FROM Tongyh_OperationLogs08
ORDER BY 表名;

\echo ''
\echo '--- 3. 索引数 ---'
SELECT COUNT(*) AS 索引总数 FROM pg_indexes WHERE schemaname = 'public';

\echo ''
\echo '--- 4. 视图 ---'
SELECT table_name FROM information_schema.views
WHERE table_schema = 'public' ORDER BY table_name;

\echo ''
\echo '--- 5. 触发器 ---'
SELECT trigger_name, event_object_table, event_manipulation
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;

\echo ''
\echo '--- 6. 自定义函数 ---'
SELECT routine_name FROM information_schema.routines
WHERE routine_schema = 'public' AND routine_name LIKE 'fn_tyh_%'
ORDER BY routine_name;

\echo ''
\echo '--- 7. 角色 ---'
SELECT * FROM Tongyh_Roles08 ORDER BY tyh_RoleId08;

\echo ''
\echo '--- 8. 2026年1月工资 ---'
SELECT g.tyh_Eno08, e.tyh_Ename08, d.tyh_Dname08, g.tyh_Level08,
       g.tyh_Sf08 AS 实发, g.tyh_Ks08 AS 扣税
FROM Tongyh_Gz08 g
JOIN Tongyh_Emp08 e ON g.tyh_Eno08 = e.tyh_Eno08
JOIN Tongyh_Depts08 d ON g.tyh_Dno08 = d.tyh_Dno08
WHERE g.tyh_Year08 = 2026 AND g.tyh_Months08 = 1
ORDER BY g.tyh_Sf08 DESC;

\echo ''
\echo '--- 9. 用户-角色 ---'
SELECT u.tyh_Username08,
       STRING_AGG(r.tyh_RoleName08, ', ' ORDER BY r.tyh_RoleName08) AS 角色
FROM Tongyh_Uspa08 u
JOIN Tongyh_UserRoles08 ur ON u.tyh_Username08 = ur.tyh_Username08
JOIN Tongyh_Roles08 r ON ur.tyh_RoleId08 = r.tyh_RoleId08
GROUP BY u.tyh_Username08 ORDER BY u.tyh_Username08;

\echo ''
\echo '============================================'
\echo '  验证完成'
\echo '============================================'
