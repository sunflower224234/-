# 公司工资管理系统 - 数据库部署指南

## 项目信息

| 项目 | 内容 |
|------|------|
| 课题 | 公司工资管理系统设计与实现 |
| 数据库 | openGauss / TongyhMIS08 |
| 命名规范 | 表名: `Tongyh_<表名>08`，列名: `tyh_<列名>08` |
| 成员 | 王沁怡、童彦衡、应昊轩、徐靖洪（第8小组） |

## 文件清单

| 文件 | 说明 |
|------|------|
| `00_run_all.sql` | **一键部署** |
| `01_init.sql` | 表空间 + 建库命令 |
| `02_tables.sql` | **11张基本表**（主键/外键/CHECK/注释） |
| `03_indexes.sql` | **26个索引** |
| `04_views.sql` | **6个视图**（含脱敏展示） |
| `05_triggers.sql` | **4个触发器**（审计+密码+解锁） |
| `06_procedures.sql` | **2个存储过程+3个辅助函数**（登录认证、工资计算） |
| `07_test_data.sql` | 测试数据（5部门12员工+1月工资自动计算） |
| `99_verify.sql` | 部署验证 |

## 数据库架构（11表）

```
Tongyh_Depts08 ──1:N── Tongyh_Emp08 ──1:N── Tongyh_Gz08
                                  │         │1:1 Tongyh_SalaryDetail08
                                  ├──1:N── Tongyh_Special08
                                  ├──1:N── Tongyh_Relations08
                                  └──1:1── Tongyh_Uspa08 ──N:M── Tongyh_Roles08
                                                      (via Tongyh_UserRoles08)
Tongyh_Wages08(dno,position,level) ──工资标准匹配→ Tongyh_Gz08
Tongyh_OperationLogs08 ← 触发器自动写入
```

## 命名规范示例

| 类型 | 格式 | 示例 |
|------|------|------|
| 表名 | `Tongyh_<Name>08` | `Tongyh_Emp08` |
| 列名 | `tyh_<Name>08` | `tyh_Eno08`, `tyh_Ename08` |
| 主键 | `pk_Tongyh_<Table>08` | `pk_Tongyh_Emp08` |
| 外键 | `fk_Tongyh_<Table>_<Col>08` | `fk_Tongyh_Emp08_dno` |
| 索引 | `idx_tyh_<desc>08` | `idx_tyh_emp_dno08` |
| 视图 | `v_tyh_<Name>08` | `v_tyh_EmpInfo08` |
| 触发器 | `trg_tyh_<Name>08` | `trg_tyh_EmpAudit08` |
| 函数 | `fn_tyh_<Name>08` | `fn_tyh_CalcSalary08` |

## 触发器（4个）

| 触发器 | 表 | 功能 |
|--------|-----|------|
| `trg_tyh_EmpAudit08` | Tongyh_Emp08 | 员工增删改自动写日志 |
| `trg_tyh_GzAudit08` | Tongyh_Gz08 | 工资增删改自动写日志 |
| `trg_tyh_PwdChange08` | Tongyh_Uspa08 | 密码修改自动更新修改时间 |
| `trg_tyh_AutoUnlock08` | Tongyh_Uspa08 | 锁定过期自动解锁 |

## 存储过程（2个核心）

| 函数 | 功能 |
|------|------|
| `fn_tyh_UserLogin08` | 用户登录认证（密码验证/锁定处理/日志记录） |
| `fn_tyh_CalcSalary08` | 计算并生成员工月度工资（含个税） |

## 部署步骤

```bash
# 1. 创建数据库
gsql -d postgres -U omm -c "
CREATE DATABASE \"TongyhMIS08\"
    WITH OWNER = \"gaussdb\" ENCODING = 'UTF8'
    TABLESPACE = data_space;
"

# 2. 一键部署
gsql -d TongyhMIS08 -U gaussdb -f 00_run_all.sql

# 3. 或逐步执行（用于课设截图）
gsql -d TongyhMIS08 -U gaussdb
\i 02_tables.sql
\i 03_indexes.sql
\i 04_views.sql
\i 05_triggers.sql
\i 06_procedures.sql
\i 07_test_data.sql
\i 99_verify.sql
```

## 测试账号（密码: `Abc@12345`）

| 用户名 | 关联员工 | 角色 |
|--------|---------|------|
| admin | - | 系统管理员 |
| zhangsan | E001 张三 | 总经理+人事 |
| lisi | E005 李四 | 财务管理员 |
| auditor | - | 审计管理员 |

## 常用操作

```sql
-- 登录
SELECT * FROM fn_tyh_UserLogin08('zhangsan', 'Abc@12345');

-- 计算工资
SELECT * FROM fn_tyh_CalcSalary08('E001', 2026, 1);

-- 查看1月工资
SELECT * FROM v_tyh_SalaryFull08 WHERE tyh_Year08 = 2026 AND tyh_Months08 = 1;

-- 查看审计日志
SELECT * FROM v_tyh_AuditLog08 LIMIT 20;
```
