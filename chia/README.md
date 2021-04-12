# How to use

`/root/chia-blockchain/` is where you compile and install chia.

All scripts in this repository are placed in the `/root/chia-blockchain/plot` directory.

1. Copy necessary files

```bash
ansible chia -m synchronize -a "src=/root/chia-blockchain/ dest=/root/chia-blockchain/"
```

2. Initialize chia worker

```bash
ansible chia -m shell -a "cd /root/chia-blockchain/plot && ./init.sh"
```

3. Auto plots

```bash
ansible chia -m shell -a "cd /root/chia-blockchain/plot && nohup ./auto-plot.sh >> test.log 2>&1 &"
```

4. Stop auto plots && kill all running plots

```bash
ansible chia -m shell -a "cd /root/chia-blockchain/plot && ./stop-auto.sh"
ansible chia -m shell -a "cd /root/chia-blockchain/plot && ./stop-all.sh"
```