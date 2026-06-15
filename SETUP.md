# 环境配置

## Linux (Ubuntu/Debian)

```bash
# 编译工具
sudo apt-get update
sudo apt-get install -y ninja-build cmake pkg-config

# GTK 开发库
sudo apt-get install -y libgtk-3-dev

# 其他依赖
sudo apt-get install -y clang libblkid-dev
```

## 验证

```bash
ninja --version
cmake --version
```

## 运行

```bash
cd /home/interset/Desktop/mobile
flutter run -d linux
```
