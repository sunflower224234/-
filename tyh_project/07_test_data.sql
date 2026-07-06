-- ============================================================
-- 公司工资管理系统 - 测试数据脚本
-- 数据库：TongyhMIS08 (openGauss)
-- ============================================================

-- 1. 角色（5种）
INSERT INTO Tongyh_Roles08 (tyh_RoleId08, tyh_RoleName08) VALUES
(1, '系统管理员'),
(2, '人事管理员'),
(3, '财务管理员'),
(4, '总经理'),
(5, '审计管理员');

-- 2. 部门（5个）
INSERT INTO Tongyh_Depts08 (tyh_Dno08, tyh_Dname08, tyh_Downer08) VALUES
('D001', '技术开发部', '张三'),
('D002', '财务管理部', '李四'),
('D003', '人力资源部', '王五'),
('D004', '市场营销部', '赵六'),
('D005', '行政管理部', '陈七');

-- 3. 员工（12名）
INSERT INTO Tongyh_Emp08 (tyh_Eno08, tyh_Dno08, tyh_Ename08, tyh_Position08, tyh_Level08,
    tyh_IdCardNumber08, tyh_PhoneNumber08, tyh_Email08, tyh_Address08) VALUES
('E001', 'D001', '张三', '部门经理',   'P4', '330106199002150011', '13800001001', 'zhangsan@company.com', '杭州市西湖区XX路1号'),
('E002', 'D001', '李明', '高级工程师', 'P3', '330106199305200022', '13800001002', 'liming@company.com',    '杭州市西湖区XX路2号'),
('E003', 'D001', '王芳', '软件工程师', 'P2', '330106199508100033', '13800001003', 'wangfang@company.com',  '杭州市西湖区XX路3号'),
('E004', 'D001', '刘洋', '初级工程师', 'P1', '330106199812010044', '13800001004', 'liuyang@company.com',   '杭州市西湖区XX路4号'),
('E005', 'D002', '李四', '部门经理',   'P4', '330106198805150055', '13800002001', 'lisi@company.com',      '杭州市拱墅区YY路1号'),
('E006', 'D002', '赵敏', '会计主管',   'P3', '330106199207200066', '13800002002', 'zhaomin@company.com',   '杭州市拱墅区YY路2号'),
('E007', 'D002', '孙磊', '出纳',       'P2', '330106199510250077', '13800002003', 'sunlei@company.com',    '杭州市拱墅区YY路3号'),
('E008', 'D003', '王五', '部门经理',   'P4', '330106198703100088', '13800003001', 'wangwu@company.com',    '杭州市滨江区ZZ路1号'),
('E009', 'D003', '周洁', '人事专员',   'P2', '330106199404150099', '13800003002', 'zhoujie@company.com',   '杭州市滨江区ZZ路2号'),
('E010', 'D004', '赵六', '部门经理',   'P4', '330106198910050111', '13800004001', 'zhaoliu@company.com',   '杭州市余杭区AA路1号'),
('E011', 'D004', '吴强', '市场专员',   'P2', '330106199608180122', '13800004002', 'wuqiang@company.com',   '杭州市余杭区AA路2号'),
('E012', 'D005', '陈七', '部门经理',   'P3', '330106199101220133', '13800005001', 'chenqi@company.com',    '杭州市上城区BB路1号');

-- 4. 基础工资标准（12条）
INSERT INTO Tongyh_Wages08 (tyh_Dno08, tyh_Position08, tyh_Level08,
    tyh_Basics08, tyh_Extra08, tyh_Gjj08, tyh_Shebao08, tyh_Riceextra08, tyh_Trafficextra08) VALUES
('D001', '部门经理',   'P4', 20000.00, 5000.00, 2400.00, 2000.00, 600.00, 400.00),
('D001', '高级工程师', 'P3', 15000.00, 3000.00, 1800.00, 1500.00, 500.00, 300.00),
('D001', '软件工程师', 'P2', 10000.00, 2000.00, 1200.00, 1000.00, 400.00, 300.00),
('D001', '初级工程师', 'P1',  6500.00, 1000.00,  800.00,  650.00, 400.00, 200.00),
('D002', '部门经理',   'P4', 18000.00, 4500.00, 2200.00, 1800.00, 600.00, 400.00),
('D002', '会计主管',   'P3', 13000.00, 2500.00, 1600.00, 1300.00, 500.00, 300.00),
('D002', '出纳',       'P2',  8000.00, 1500.00, 1000.00,  800.00, 400.00, 300.00),
('D003', '部门经理',   'P4', 17000.00, 4000.00, 2000.00, 1700.00, 600.00, 400.00),
('D003', '人事专员',   'P2',  7500.00, 1200.00,  900.00,  750.00, 400.00, 300.00),
('D004', '部门经理',   'P4', 16000.00, 4000.00, 1900.00, 1600.00, 600.00, 500.00),
('D004', '市场专员',   'P2',  7000.00, 1500.00,  850.00,  700.00, 400.00, 400.00),
('D005', '部门经理',   'P3', 14000.00, 3000.00, 1700.00, 1400.00, 500.00, 300.00);

-- 5. 工资明细（2026年1月，12条）
INSERT INTO Tongyh_SalaryDetail08 (tyh_Eno08, tyh_Year08, tyh_Months08,
    tyh_Wday08, tyh_Sj08, tyh_Cd08, tyh_Jiaban08, tyh_Allday08,
    tyh_AbsenceDeduction08, tyh_OtherDeduction08) VALUES
('E001', 2026, 1, 22, 22, 0, 0,      500.00, 0,    0),
('E002', 2026, 1, 22, 21, 1, 500.00, 500.00, 0,    0),
('E003', 2026, 1, 22, 22, 0, 200.00, 500.00, 0,    0),
('E004', 2026, 1, 22, 20, 2, 300.00, 0,      100.00, 0),
('E005', 2026, 1, 22, 22, 0, 0,      500.00, 0,    0),
('E006', 2026, 1, 22, 22, 0, 0,      500.00, 0,    0),
('E007', 2026, 1, 22, 22, 0, 100.00, 500.00, 0,    50.00),
('E008', 2026, 1, 22, 21, 1, 0,      500.00, 0,    0),
('E009', 2026, 1, 22, 22, 0, 0,      500.00, 0,    0),
('E010', 2026, 1, 22, 22, 0, 0,      500.00, 0,    0),
('E011', 2026, 1, 22, 18, 4, 200.00, 0,      300.00, 0),
('E012', 2026, 1, 22, 22, 0, 0,      500.00, 0,    0);

-- 6. 专项附加扣除（6条）
INSERT INTO Tongyh_Special08 (tyh_Sno08, tyh_Eno08, tyh_Year08,
    tyh_ChildEdu08, tyh_ContinueEdu08, tyh_MedicalTreat08,
    tyh_HouseLoans08, tyh_HouseRent08, tyh_SupportElderly08, tyh_ChildCare08) VALUES
('S2026001', 'E001', 2026, 12000.00, 0,      0,       12000.00, 0,       12000.00, 0),
('S2026002', 'E002', 2026, 12000.00, 0,      0,       12000.00, 0,       12000.00, 12000.00),
('S2026003', 'E003', 2026, 0,        4800.00, 0,       0,        18000.00, 0,        0),
('S2026004', 'E005', 2026, 24000.00, 0,      0,       12000.00, 0,       12000.00, 0),
('S2026005', 'E008', 2026, 12000.00, 0,      15000.00, 0,       15000.00, 12000.00, 0),
('S2026006', 'E010', 2026, 0,        0,      0,       12000.00, 0,       0,        0);

-- 7. 家属关系（6条）
INSERT INTO Tongyh_Relations08 (tyh_IdNumber08, tyh_Eno08, tyh_Jname08, tyh_Relationship08) VALUES
('330106198502150021', 'E001', '张丽',   '配偶'),
('330106201504100012', 'E001', '张小宝', '子女'),
('330106195508150041', 'E003', '王大明', '父亲'),
('330106195612250042', 'E003', '陈秀英', '母亲'),
('330106198703100051', 'E005', '赵敏敏', '配偶'),
('330106195712010071', 'E008', '王建国', '父亲');

-- 8. 用户（8个，密码 Abc@12345）
INSERT INTO Tongyh_Uspa08 (tyh_Username08, tyh_Eno08, tyh_Password08,
    tyh_Encryptedpassword08, tyh_LastPasswordChange08, tyh_FailedAttempts08, tyh_LockTime08) VALUES
('admin',      NULL,   'Abc@12345', fn_tyh_HashPwd08('Abc@12345'), CURRENT_TIMESTAMP, 0, NULL),
('zhangsan',   'E001', 'Abc@12345', fn_tyh_HashPwd08('Abc@12345'), CURRENT_TIMESTAMP, 0, NULL),
('lisi',       'E005', 'Abc@12345', fn_tyh_HashPwd08('Abc@12345'), CURRENT_TIMESTAMP, 0, NULL),
('wangwu',     'E008', 'Abc@12345', fn_tyh_HashPwd08('Abc@12345'), CURRENT_TIMESTAMP, 0, NULL),
('zhaoliu',    'E010', 'Abc@12345', fn_tyh_HashPwd08('Abc@12345'), CURRENT_TIMESTAMP, 0, NULL),
('auditor',    NULL,   'Abc@12345', fn_tyh_HashPwd08('Abc@12345'), CURRENT_TIMESTAMP, 0, NULL),
('hr_manager', 'E009', 'Abc@12345', fn_tyh_HashPwd08('Abc@12345'), CURRENT_TIMESTAMP, 0, NULL),
('fin_manager','E006', 'Abc@12345', fn_tyh_HashPwd08('Abc@12345'), CURRENT_TIMESTAMP, 0, NULL);

-- 9. 用户角色分配
INSERT INTO Tongyh_UserRoles08 (tyh_Username08, tyh_RoleId08) VALUES
('admin',       1),
('zhangsan',    4), ('zhangsan',    2),
('lisi',        3),
('wangwu',      2),
('zhaoliu',     4),
('auditor',     5),
('hr_manager',  2),
('fin_manager', 3);

-- 10. 计算并生成1月工资
SELECT fn_tyh_CalcSalary08('E001', 2026, 1);
SELECT fn_tyh_CalcSalary08('E002', 2026, 1);
SELECT fn_tyh_CalcSalary08('E003', 2026, 1);
SELECT fn_tyh_CalcSalary08('E004', 2026, 1);
SELECT fn_tyh_CalcSalary08('E005', 2026, 1);
SELECT fn_tyh_CalcSalary08('E006', 2026, 1);
SELECT fn_tyh_CalcSalary08('E007', 2026, 1);
SELECT fn_tyh_CalcSalary08('E008', 2026, 1);
SELECT fn_tyh_CalcSalary08('E009', 2026, 1);
SELECT fn_tyh_CalcSalary08('E010', 2026, 1);
SELECT fn_tyh_CalcSalary08('E011', 2026, 1);
SELECT fn_tyh_CalcSalary08('E012', 2026, 1);

DO $$
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE '测试数据插入完成！';
    RAISE NOTICE '部门5+员工12+工资标准12+明细12+专项6+家属6+用户8';
    RAISE NOTICE '默认密码：Abc@12345';
    RAISE NOTICE '============================================';
END $$;
