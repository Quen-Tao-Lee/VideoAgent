"""
Health Tracker Mini-Program
健康行为监控与目标达成小程序

Main entry point for the health tracker application.
"""
import argparse
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from health_tracker.api.server import HealthTrackerAPI
from health_tracker.config.settings import get_config


def main():
    """主函数"""
    parser = argparse.ArgumentParser(
        description='Health Tracker Mini-Program - 健康行为监控与目标达成小程序'
    )
    
    parser.add_argument(
        '--host',
        type=str,
        default=None,
        help='API server host (default: 0.0.0.0)'
    )
    
    parser.add_argument(
        '--port',
        type=int,
        default=None,
        help='API server port (default: 5000)'
    )
    
    parser.add_argument(
        '--debug',
        action='store_true',
        help='Enable debug mode'
    )
    
    parser.add_argument(
        '--env',
        type=str,
        choices=['development', 'production'],
        default='development',
        help='Environment (default: development)'
    )
    
    parser.add_argument(
        '--db-url',
        type=str,
        default=None,
        help='Database URL (default: sqlite:///health_tracker.db)'
    )
    
    args = parser.parse_args()
    
    # 获取配置
    config = get_config(args.env)
    
    # 使用命令行参数覆盖配置
    host = args.host or config.API_HOST
    port = args.port or config.API_PORT
    debug = args.debug or config.API_DEBUG
    db_url = args.db_url or config.DATABASE_URL
    
    print("=" * 60)
    print("Health Tracker Mini-Program")
    print("健康行为监控与目标达成小程序")
    print("=" * 60)
    print(f"Environment: {args.env}")
    print(f"Database: {db_url}")
    print(f"API Server: http://{host}:{port}")
    print(f"Debug Mode: {debug}")
    print("=" * 60)
    print("\nStarting server...")
    print("Press Ctrl+C to stop\n")
    
    # 创建并运行API服务
    try:
        api = HealthTrackerAPI(db_url=db_url)
        api.run(host=host, port=port, debug=debug)
    except KeyboardInterrupt:
        print("\n\nShutting down server...")
        print("Goodbye!")
    except Exception as e:
        print(f"\n\nError: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
