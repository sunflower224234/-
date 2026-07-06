"""数据库连接辅助模块"""
import pg8000.native
from flask import g
from config import DB_CONFIG


def get_db():
    """获取数据库连接（请求级复用）"""
    if 'db' not in g:
        g.db = pg8000.native.Connection(
            host=DB_CONFIG['host'],
            port=DB_CONFIG['port'],
            user=DB_CONFIG['user'],
            password=DB_CONFIG['password'],
            database=DB_CONFIG['database'],
        )
    return g.db


def close_db(error=None):
    """关闭数据库连接"""
    db = g.pop('db', None)
    if db is not None:
        try:
            db.close()
        except Exception:
            pass


def _convert_params(sql, params):
    """将 %s 占位符转换为 pg8000 native 的 :pN 命名参数风格"""
    if not params:
        return sql, {}
    # Replace each %s with :pN
    named_params = {}
    new_sql = sql
    for i, p in enumerate(params):
        pname = f"p{i}"
        # Replace first occurrence of %s
        idx = new_sql.find('%s')
        if idx != -1:
            new_sql = new_sql[:idx] + ':' + pname + new_sql[idx+2:]
        named_params[pname] = p
    return new_sql, named_params


def query(sql, params=None):
    """执行查询，返回结果列表"""
    db = get_db()
    if params:
        new_sql, named = _convert_params(sql, params)
        rows = db.run(new_sql, **named)
    else:
        rows = db.run(sql)
    if not rows:
        return []
    return rows


def execute(sql, params=None):
    """执行增删改语句"""
    db = get_db()
    if params:
        new_sql, named = _convert_params(sql, params)
        return db.run(new_sql, **named)
    else:
        return db.run(sql)


def call_proc(name, params=None):
    """调用存储过程/函数，返回结果行列表"""
    db = get_db()
    if params:
        named_params = {}
        placeholders = []
        for i, p in enumerate(params):
            pname = f"p{i}"
            placeholders.append(':' + pname)
            named_params[pname] = p
        return db.run(f"SELECT * FROM {name}({','.join(placeholders)})", **named_params)
    else:
        return db.run(f"SELECT * FROM {name}()")
