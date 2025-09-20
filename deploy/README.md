# 阿里云余额监控机器人部署指南

本指南将帮助您快速部署阿里云余额监控Telegram机器人。

## 项目简介

这是一个精简的Telegram机器人，专门用于监控阿里云账户余额。主要功能：

- 通过GetCreditInfo API查询用户余额信息
- 支持多账户绑定和监控
- 余额预警通知
- 简单易用的Telegram界面

## 前置要求

### 必需条件
- Docker 和 Docker Compose
- Telegram Bot Token
- 管理员Telegram用户ID

### 可选条件
- 域名（用于webhook模式）
- 阿里云Access Key（也可通过机器人命令设置）

## 快速部署

### 1. 下载项目

```bash
git clone <your-repo-url>
cd botfather
```

### 2. 配置环境变量

```bash
# 复制配置文件模板
cp .env.example .env

# 编辑配置文件
nano .env
```

必须配置的参数：
```env
BOT_TOKEN=your_telegram_bot_token_here
WEBHOOK_URL=https://your-domain.com  # 或使用polling模式可留空
ADMIN_CHAT_IDS=your_telegram_user_id
```

### 3. 使用Docker部署

```bash
# 运行部署脚本
chmod +x deploy/deploy.sh
./deploy/deploy.sh
```

或者手动部署：

```bash
# 创建数据目录
mkdir -p data logs

# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f
```

## 配置说明

### 环境变量详解

| 变量名 | 必需 | 说明 | 示例 |
|--------|------|------|------|
| BOT_TOKEN | ✅ | Telegram Bot Token | 123456:ABC-DEF... |
| WEBHOOK_URL | ❌ | Webhook URL（不设置则使用polling） | https://your-domain.com |
| PORT | ❌ | 服务端口 | 5000 |
| ADMIN_CHAT_IDS | ✅ | 管理员用户ID（逗号分隔） | 123456789,987654321 |
| CHECK_INTERVAL | ❌ | 监控间隔（秒） | 300 |
| ENABLE_MONITORING | ❌ | 是否启用自动监控 | true |
| DATABASE_PATH | ❌ | 数据库文件路径 | bot_data.db |
| ALIYUN_ACCESS_KEY_ID | ❌ | 阿里云AK | LTAI... |
| ALIYUN_ACCESS_KEY_SECRET | ❌ | 阿里云SK | ... |
| ALIYUN_RESELLER_TEST_UID | ❌ | 测试用户UID | 1234567890123456 |
| PROXY_URL | ❌ | 代理URL | http://127.0.0.1:7890 |
| LOG_LEVEL | ❌ | 日志级别 | INFO |

## 使用说明

### 1. 启动机器人

首次使用时，向机器人发送 `/start` 命令：

1. 如果未配置阿里云凭证，机器人会提示输入AK/SK
2. 按格式发送：`AK:您的AccessKeyID` 和 `SK:您的AccessKeySecret`
3. 凭证验证成功后，即可使用机器人功能

### 2. 主要命令

- `/start` - 启动机器人并显示主菜单
- `/bind_aliyun [UID] [备注] [低余额阈值] [突降阈值]` - 绑定阿里云账号
- `/unbind_aliyun [UID]` - 解绑阿里云账号
- `/list_aliyun` - 查看绑定列表
- `/aliyun_balance` - 查询所有账号余额
- `/monitor_status` - 查看监控状态
- `/start_monitor` - 启动监控
- `/stop_monitor` - 停止监控
- `/help` - 显示帮助信息

### 3. 绑定账号示例

```
/bind_aliyun 1234567890123456 测试账号 100 50
```

这将绑定UID为1234567890123456的账号，备注为"测试账号"，低余额阈值100元，突降阈值50元。

## 服务管理

### Docker方式

```bash
# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 重启服务
docker-compose restart

# 停止服务
docker-compose down

# 更新并重启
docker-compose down
docker-compose build
docker-compose up -d
```

### 健康检查

```bash
# 检查服务状态
curl http://localhost:5000/health

# 如果配置了域名
curl https://your-domain.com/health
```

## 故障排除

### 常见问题

1. **容器启动失败**
   ```bash
   docker-compose logs
   ```

2. **端口被占用**
   ```bash
   netstat -tlnp | grep :5000
   ```

3. **权限问题**
   ```bash
   # 检查数据目录权限
   ls -la data/

   # 修复权限
   sudo chown -R 1000:1000 data/ logs/
   ```

4. **网络连接问题**
   ```bash
   # 测试Telegram API连接
   curl -X GET "https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getMe"
   ```

### 日志查看

```bash
# 查看应用日志
docker-compose logs -f aliyun-balance-bot

# 查看特定时间的日志
docker-compose logs --since="2024-01-01T00:00:00" aliyun-balance-bot

# 查看最近100行日志
docker-compose logs --tail=100 aliyun-balance-bot
```

## 数据备份

```bash
# 备份数据库
cp data/bot_data.db backup/bot_data_$(date +%Y%m%d_%H%M%S).db

# 备份配置
cp .env backup/.env_$(date +%Y%m%d_%H%M%S)
```

## 更新应用

```bash
# 拉取最新代码
git pull

# 重新构建并启动
docker-compose down
docker-compose build
docker-compose up -d
```

## 安全建议

1. **保护配置文件**
   ```bash
   chmod 600 .env
   ```

2. **定期备份数据**
   ```bash
   # 添加到crontab
   0 2 * * * cp /path/to/data/bot_data.db /path/to/backup/
   ```

3. **监控资源使用**
   ```bash
   docker stats
   ```

4. **使用HTTPS**
   - 配置SSL证书
   - 使用反向代理（如Nginx）

## 性能优化

1. **资源限制**
   ```yaml
   # 在docker-compose.yml中添加
   deploy:
     resources:
       limits:
         memory: 512M
         cpus: '0.5'
   ```

2. **日志轮转**
   ```bash
   # 配置Docker日志轮转
   echo '{"log-driver":"json-file","log-opts":{"max-size":"10m","max-file":"3"}}' | sudo tee /etc/docker/daemon.json
   sudo systemctl restart docker
   ```

## 支持

如果遇到问题：

1. 检查日志输出
2. 验证配置文件
3. 确认网络连接
4. 查看Docker状态

项目地址：[GitHub Repository]
