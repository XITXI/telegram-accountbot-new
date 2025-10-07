#!/bin/bash

# 阿里云余额监控机器人简化部署脚本

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查Docker环境
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装，请先安装Docker"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose未安装，请先安装Docker Compose"
        exit 1
    fi

    log_info "Docker环境检查通过"
}

# 配置环境变量
setup_config() {
    if [[ ! -f ".env" ]]; then
        cp .env.example .env
        log_info "已创建.env配置文件"
        log_warn "请编辑.env文件，配置必要的参数："
        echo "  - BOT_TOKEN: Telegram Bot Token"
        echo "  - WEBHOOK_URL: Webhook URL"
        echo "  - ADMIN_CHAT_IDS: 管理员Telegram用户ID"
        echo ""
        read -p "按回车键继续..."
    fi
}

# 测试连接
test_connection() {
    log_info "正在测试与Telegram API的连通性..."

    # 使用curl测试网络连接，设置15秒超时
    if curl --connect-timeout 15 -s -o /dev/null https://api.telegram.org; then
        log_info "✅ 与Telegram API连通性测试通过"
        return 0
    else
        log_error "❌ 无法连接到Telegram API服务器"
        log_warn "可能的解决方案："
        echo "  1. 检查服务器的网络连接和防火墙设置。"
        echo "  2. 确认服务器可以访问外网，特别是 api.telegram.org。"
        echo "  3. 如果在网络受限的环境，请在 .env 文件中配置 PROXY_URL。"
        return 1
    fi
}

# 部署应用
deploy() {
    log_info "开始部署..."

    # 创建数据目录
    mkdir -p data logs

    # 停止旧容器
    docker-compose down 2>/dev/null || true

    # 构建并启动
    docker-compose build
    docker-compose up -d

    log_info "部署完成！"

    # 等待服务启动
    sleep 10

    # 检查状态
    if docker-compose ps | grep -q "Up"; then
        log_info "服务启动成功"
        log_info "访问 http://localhost:5000/health 检查服务状态"
        log_info "查看日志: docker-compose logs -f"

        # 等待一段时间让服务完全启动
        log_info "等待服务完全启动..."
        sleep 5

        # 检查容器日志中是否有错误
        if docker-compose logs --tail=20 | grep -i "error\|failed\|timeout"; then
            log_warn "检测到可能的错误，请查看完整日志"
        else
            log_info "✅ 服务运行正常"
        fi
    else
        log_error "服务启动失败，请查看日志: docker-compose logs"
    fi
}

# 主函数
main() {
    log_info "阿里云余额监控机器人部署脚本"

    check_docker
    setup_config

    # 在部署前测试连接
    if test_connection; then
        deploy
    else
        log_error "连接测试失败，取消部署"
        log_info "请解决网络连接问题后重试"
        exit 1
    fi
}

main "$@"


