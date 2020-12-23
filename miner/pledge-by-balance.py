#!/usr/bin/env python3
# -*- coding: UTF-8 -*-

import requests
import time
import os
import subprocess as sp
import logging

auto_withdraw_balance = 5
auto_pledge_balance = 5
parallel_jobs = 20

daemon_url = "http://127.0.0.1:1234/rpc/v0"
daemon_token = "your daemon token here"

miner_url = "http://172.16.119.1:2345/rpc/v0"
miner_token = "your miner token here"

os.environ["LOTUS_PATH"] = "/tank1/filecash/.lotus"
os.environ["LOTUS_MINER_PATH"] = "/tank1/filecash/.lotusminer"
os.environ["FIL_PROOFS_PARAMETER_CACHE"] = "/tank1/filecash-proof-parameters"

LOG_FORMAT = "%(asctime)s %(levelname)s %(message)s"
DATE_FORMAT = "%m-%d-%Y %H:%M:%S"

logging.basicConfig(filename='pledge.log', level=logging.INFO,
                    format=LOG_FORMAT, datefmt=DATE_FORMAT)

# Call any supported API
def call_any(target, method, params):
    if target == "daemon":
        url = daemon_url
        token = daemon_token
    elif target == "miner":
        url = miner_url
        token = miner_token
    else:
        return 0
    headers = {
        'User-Agent': '',
        'accept': 'application/json, text/plain, */*',
        'referer': '',
        'content-type': 'text/plain; charset=utf-8'
    }
    url_params = {
        'token': token
    }
    data = {
        "jsonrpc": "2.0",
        "id": 114514,
        "method": "Filecoin." + method,
        "params": params
    }
    try:
        resp = requests.post(url, headers=headers, params=url_params, json=data)
        return resp.json()
    except requests.exceptions.RequestException as e:
        logging.error(e)
    except Exception as e:
        logging.error(e)
    return 0


if __name__ == "__main__":
    while True:
        # Check if miner's balance is ready for withdraw
        miner_wallet = call_any("miner", "ActorAddress", None)["result"]
        miner_balance_verbose = call_any("daemon", "StateMinerAvailableBalance", [miner_wallet, []])["result"]
        miner_balance = int(int(miner_balance_verbose)/(10**18))
        logging.info("Miner balance: " + str(miner_balance))
        if miner_balance > auto_withdraw_balance:
            # Withdraw balance, there is no RPC method
            msg_id_verbose = sp.Popen(["./lotus-miner", "actor", "withdraw"], stdout=sp.PIPE, stderr=sp.PIPE).stdout
            msg_id_verbose.wait()
            msg_id = msg_id_verbose.readline().decode(encoding='UTF-8').strip().split(" ")[-1]
            # Wait a moment please
            sp.call(["./lotus", "state", "wait-msg", msg_id])

        # Check current jobs
        pre_jobs_count = 0
        cur_jobs_count = 0
        av_jobs_count = 0
        worker_jobs = call_any("miner", "WorkerJobs", None)["result"]
        for key, jobs in worker_jobs.items():
            # Miner
            if key == "0":
                continue
            # Worker
            for job in jobs:
                cur_jobs_count += 1
                if "precommit" in job["Task"]:
                    pre_jobs_count += 1
            av_jobs_count += parallel_jobs - cur_jobs_count
        logging.info("PreCommit jobs: " + str(pre_jobs_count))

        # Check wallet balance
        def_wallet = call_any("daemon", "WalletDefaultAddress", None)["result"]
        def_balance_verbose = call_any("daemon", "WalletBalance", [def_wallet])["result"]
        def_balance = int(int(def_balance_verbose)/(10**18))
        logging.info("Available balance: " + str(def_balance))

        # If balance - precommit > auto_pledge_balance, lol
        count = def_balance - pre_jobs_count
        if count > auto_pledge_balance:
            for i in range(count):
                # Remaining workload
                if av_jobs_count < 1:
                    logging.warning("Worker overload, touch fish.")
                    break
                sp.call(["./lotus-miner", "sectors", "pledge"])
                logging.info("Make a sector. (TODO: {todo}, Available: {av})".format(todo=i, av=av_jobs_count))
                av_jobs_count -= 1
                # Wait for add piece
                time.sleep(300)
        time.sleep(60)
