-- ============================================================
-- 公司工资管理系统 - 数据库初始化
-- 数据库：openGauss
-- 库名：TongyhMIS08
-- 命名规范：表名 Tongyh_<表名>08，列名 tyh_<列名>08
-- ============================================================

-- 1. 创建表空间
CREATE TABLESPACE data_space RELATIVE LOCATION 'tablespace/data_space';
CREATE TABLESPACE log_space  RELATIVE LOCATION 'tablespace/log_space';

-- 2. 创建数据库（请在命令行执行，不能在事务块中运行）
-- \c postgres
-- CREATE DATABASE "TongyhMIS08"
--     WITH OWNER = "gaussdb"
--     ENCODING = 'UTF8'
--     LC_COLLATE = 'en_US.UTF-8'
--     LC_CTYPE = 'en_US.UTF-8'
--     TABLESPACE = data_space
--     CONNECTION LIMIT = -1;
-- \c "TongyhMIS08"

DO $$
BEGIN
    RAISE NOTICE '表空间创建完成。';
    RAISE NOTICE '请手动创建数据库 TongyhMIS08 后继续执行 02_tables.sql';
END $$;
