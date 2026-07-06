"""员工工资管理系统 - Flask 主应用入口"""
from flask import Flask
from config import SECRET_KEY
from db import close_db


def create_app():
    app = Flask(__name__)
    app.secret_key = SECRET_KEY
    app.config['PERMANENT_SESSION_LIFETIME'] = 3600

    # 注册数据库清理
    app.teardown_appcontext(close_db)

    # 注册蓝图
    from blueprints.auth_bp import auth_bp
    from blueprints.dashboard_bp import dashboard_bp
    from blueprints.employee_bp import employee_bp
    from blueprints.department_bp import department_bp
    from blueprints.wages_bp import wages_bp
    from blueprints.attendance_bp import attendance_bp
    from blueprints.salary_bp import salary_bp
    from blueprints.special_bp import special_bp
    from blueprints.user_bp import user_bp
    from blueprints.log_bp import log_bp

    app.register_blueprint(auth_bp, url_prefix='/auth')
    app.register_blueprint(dashboard_bp, url_prefix='/')
    app.register_blueprint(employee_bp, url_prefix='/employees')
    app.register_blueprint(department_bp, url_prefix='/departments')
    app.register_blueprint(wages_bp, url_prefix='/wages')
    app.register_blueprint(attendance_bp, url_prefix='/attendance')
    app.register_blueprint(salary_bp, url_prefix='/salary')
    app.register_blueprint(special_bp, url_prefix='/special')
    app.register_blueprint(user_bp, url_prefix='/users')
    app.register_blueprint(log_bp, url_prefix='/logs')

    return app


if __name__ == '__main__':
    app = create_app()
    app.run(debug=True, host='0.0.0.0', port=5000, threaded=True)
