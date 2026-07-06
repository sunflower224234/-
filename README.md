# 公司工资管理系统（TongyhMIS08）

基于 openGauss + Python Flask 的全栈工资管理系统，涵盖部门管理、员工管理、考勤、工资计算、个税扣除、权限控制和审计日志等全链路功能。

## 技术栈

| 层级 | 技术 |
|------|------|
| 数据库 | openGauss 6.0（Docker 部署） |
| 后端 | Python Flask 3.x + pg8000 |
| 前端 | Bootstrap 5 + Chart.js + Jinja2 |
| 数据库工具 | Navicat Premium Lite 17 |

## 项目结构

```
├── tyh_project/          # 数据库脚本（SQL）
│   ├── 01_init.sql          # 表空间
│   ├── 02_tables.sql        # 11 张基本表
│   ├── 03_indexes.sql       # 26 个索引
│   ├── 04_views.sql         # 6 个视图
│   ├── 05_triggers.sql      # 4 个触发器
│   ├── 06_procedures.sql    # 5 个存储过程/函数
│   ├── 07_test_data.sql     # 测试数据
│   ├── 00_run_all.sql       # 一键部署入口
│   ├── 99_verify.sql        # 验证脚本
│   └── deploy.py            # Python 自动化部署
│
└── tyh_webapp/           # Flask Web 应用
    ├── app.py               # 应用入口
    ├── config.py            # 数据库连接配置
    ├── db.py                # pg8000 连接封装
    ├── decorators.py        # 登录/角色权限装饰器
    ├── blueprints/          # 10 个蓝图模块
    │   ├── auth_bp.py           # 登录认证
    │   ├── dashboard_bp.py      # 仪表盘（管理员/普通员工双视图）
    │   ├── employee_bp.py       # 员工管理
    │   ├── department_bp.py     # 部门管理
    │   ├── wages_bp.py          # 工资标准管理
    │   ├── attendance_bp.py     # 考勤明细
    │   ├── salary_bp.py         # 工资计算 + 导出
    │   ├── special_bp.py        # 专项附加扣除
    │   ├── user_bp.py           # 用户与角色管理
    │   └── log_bp.py            # 审计日志
    ├── templates/           # Jinja2 模板（22 个页面）
    └── static/              # CSS/JS 静态资源
```

## 数据库设计

### 基本表（11 张）

| 表名 | 说明 |
|------|------|
| Tongyh_Depts08 | 部门信息表 |
| Tongyh_Emp08 | 员工信息表 |
| Tongyh_Wages08 | 基础工资标准表（部门+职位+职级 三维匹配） |
| Tongyh_SalaryDetail08 | 工资明细/考勤表 |
| Tongyh_Gz08 | 工资结果表（历史快照） |
| Tongyh_Special08 | 专项附加扣除表（7 项个税扣除） |
| Tongyh_Relations08 | 家属关系表 |
| Tongyh_Roles08 | 角色表 |
| Tongyh_Uspa08 | 用户密码表 |
| Tongyh_UserRoles08 | 用户角色关联表 |
| Tongyh_OperationLogs08 | 操作日志表 |

### 视图（6 个）

- `v_tyh_EmpInfo08` — 员工信息 + 敏感数据脱敏
- `v_tyh_SalaryFull08` — 工资完整明细（跨 5 表 JOIN）
- `v_tyh_SpecialSummary08` — 专项扣除年度汇总
- `v_tyh_UserRoles08` — 用户角色权限 + 账户状态
- `v_tyh_AuditLog08` — 审计日志（近 180 天）
- `v_tyh_DeptSalaryStats08` — 部门工资统计

### 触发器（4 个）

- `trg_tyh_EmpAudit08` — 员工表增删改审计
- `trg_tyh_GzAudit08` — 工资表增删改审计
- `trg_tyh_PwdChange08` — 密码修改自动跟踪
- `trg_tyh_AutoUnlock08` — 锁定到期自动解锁

### 存储过程（5 个）

- `fn_tyh_UserLogin08` — 用户登录认证（含锁定/解锁/日志）
- `fn_tyh_CalcSalary08` — 工资计算（基础工资 + 考勤 + 专项 + 个税 → 实发）
- `fn_tyh_CalcTax08` — 7 级超额累进税率个税计算
- `fn_tyh_HashPwd08` — 密码哈希
- `fn_tyh_CheckPwd08` — 密码复杂度校验

## 权限体系（RBAC）

| 角色 | 权限 |
|------|------|
| 系统管理员（1） | 全部功能 + 用户管理 + 角色分配 |
| 人事管理员（2） | 员工/部门/考勤/专项扣除管理 |
| 财务管理员（3） | 工资标准/工资计算/工资查询 |
| 总经理（4） | 全公司数据查看（只读） |
| 审计管理员（5） | 仅审计日志查看 |
| 普通员工 | 个人仪表盘/工资/考勤/专项扣除 + 工资条导出 |

## 快速开始

### 1. 环境要求

- Docker（运行 openGauss）
- Python 3.10+
- Navicat（或其他 PostgreSQL 兼容工具）

### 2. 部署数据库

```bash
# 启动 openGauss 容器
docker run -d --name opengauss_db -p 5432:5432 \
    -e GS_PASSWORD=YourPassword \
    enmotech/opengauss:latest

# 一键部署（Python）
cd tyh_project
pip install pg8000
python deploy.py

# 或手动执行 SQL
# 在 Navicat 中依次执行 02~07 号脚本
```

### 3. 启动 Web 应用

```bash
cd tyh_webapp

# 修改 config.py 中的数据库连接配置
pip install flask pg8000
python app.py
```

浏览器访问 `http://localhost:5000`。

### 4. 测试账号

| 用户名 | 密码 | 角色 |
|--------|------|------|
| admin | Abc@12345 | 系统管理员 |
| zhangsan | Abc@12345 | 总经理 + 人事管理员 |
| lisi | Abc@12345 | 财务管理员 |
| auditor | Abc@12345 | 审计管理员 |
| liming | Abc@12345 | 普通员工 |

## 核心亮点

1. **全链路工资计算**：基础工资 → 考勤明细 → 七项专项扣除 → 7 级累进个税 → 实发工资
2. **P1-P4 职级工资体系**：部门 × 职位 × 职级 三维匹配基础工资标准
3. **等保三级安全**：密码复杂度、MD5 哈希、5 次锁定 30 分钟、敏感信息脱敏、操作全审计
4. **RBAC 五角色权限**：用户-角色多对多，侧边栏 + 路由 + 数据库三层控制
5. **双视图仪表盘**：管理员看全公司统计图表，普通员工看个人工资趋势
6. **工资条 CSV 导出**：一键导出员工工资历史为 CSV 文件

## 命名规范

| 对象 | 格式 | 示例 |
|------|------|------|
| 表 | `Tongyh_{name}08` | `Tongyh_Emp08` |
| 列 | `tyh_{name}08` | `tyh_Eno08` |
| 视图 | `v_tyh_{name}08` | `v_tyh_EmpInfo08` |
| 索引 | `idx_tyh_{name}08` | `idx_tyh_emp_dno08` |
| 触发器 | `trg_tyh_{name}08` | `trg_tyh_EmpAudit08` |
| 函数 | `fn_tyh_{name}08` | `fn_tyh_CalcSalary08` |
