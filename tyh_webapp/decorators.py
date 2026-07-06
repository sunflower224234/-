"""权限装饰器模块"""
from functools import wraps
from flask import session, redirect, url_for, flash


def login_required(f):
    """登录校验装饰器：未登录重定向到登录页"""
    @wraps(f)
    def decorated(*args, **kwargs):
        if 'username' not in session:
            flash('请先登录', 'warning')
            return redirect(url_for('auth.login'))
        return f(*args, **kwargs)
    return decorated


def role_required(role_ids):
    """角色权限装饰器：检查用户是否拥有指定角色之一
    Args:
        role_ids: 允许访问的角色ID列表，如 [1, 3]
    """
    def decorator(f):
        @wraps(f)
        def decorated(*args, **kwargs):
            if 'username' not in session:
                flash('请先登录', 'warning')
                return redirect(url_for('auth.login'))
            user_roles = session.get('role_ids', [])
            if not any(r in user_roles for r in role_ids):
                flash('权限不足，无法访问此功能', 'danger')
                return redirect(url_for('dashboard.index'))
            return f(*args, **kwargs)
        return decorated
    return decorator
