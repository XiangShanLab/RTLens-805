# 在开芯院 open08 服务器上运行 RTLens
由于 open08 服务器不能通过远程桌面登录，如果需要使用开源工具查看波形图，并分析模块之间的连接关系，可以使用本仓库提供的 RTLens 项目。在 open08 服务器上， 使用 RTLens 需要进行额外的配置。

## 第一次使用——配置环境
执行以下命令
```
bash init_env.sh
```

## 使用 RTLens
```
source env.sh
export LD_LIBRARY_PATH="$PWD/.deps/qt-xcb-libs/lib:${LD_LIBRARY_PATH:-}"
export QT_QPA_PLATFORM=xcb

xdpyinfo >/dev/null
python -c 'from PySide6.QtWidgets import QApplication; app=QApplication([]); print(app.platformName())'

.venv/bin/python rtlens/tools/gui_regression_cases.py --mode run --case deep_case
```
第五个命令应该输出 xcb，第六个命令应该输出 PASS deep case session exited successfully，如果是这样的话，接下来就可以执行以下指令并查看波形图了
```
.venv/bin/python -m rtlens --ui qt --filelist ~/xs-env/XiangShan/build/rtl/filelist.f --top SimTop
```

## TODO 待改进的内容
1）内存占用率太高，目前保守估计需要40GB空闲内存才能跑起来，内存不足会直接报错
2）目前模块解析的timout过短，仅有240秒，对于香山这种复杂设计来说根本不够