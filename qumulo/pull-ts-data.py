#!/usr/bin/env python3
# Copyright (c) 2017 Qumulo, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

import argparse
import csv
import os
import time
import sys

from typing import Any, Mapping, List, Sequence

from qumulo.rest_client import RestClient


ts = time.time()

myhost = os.uname()[1]
CSV_FILENAME = 'qumulo-timeseries-data-' + str(ts) + '-' + str(myhost) + '.csv'
COLUMNS_TO_PROCESS = [
    'iops.read.rate',
    'iops.write.rate',
    'throughput.read.rate',
    'throughput.write.rate',
    'latency.read.rate',
    'latency.write.rate'
]

def parse_args(args: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description='Get time series data from a Qumulo cluster, write to CSV',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument(
        'host',
        default='10.44.0.4',
        help='Qumulo Cluster to communicate with'
    )
    parser.add_argument(
        '-u',
        '--user',
        default='admin',
        help='Username for authentication'
    )
    parser.add_argument(
        '-p',
        '--password',
        default='Admin123',
        help='Password for authentication'
    )
    parser.add_argument(
        '-P',
        '--port',
        type=int,
        default=8000,
        help='REST Port for communicating with the cluster'
    )
    return parser.parse_args(args)


def calculate_begin_time(csv_file_name: str) -> int:
    """
    At most, we'll grab 1 day of data, but if we already have some data
    present, we can just request data since then.
    """
    last_line = None
    if os.path.exists(csv_file_name):
        # read to the last line in the file
        with open(csv_file_name, 'r') as csvfile:
            reader = csv.reader(csvfile)
            for row in reader:
                last_line = row

    if last_line is not None:
        return int(last_line[0]) + 5
    return int(time.time()) - 60 * 60 * 24


def read_time_series_from_cluster(
    host: str,
    user: str,
    password: str,
    port: int
) -> List[Mapping[str, Any]]:
    """
    Communicates with the cluster to grab the analytics in time series format
    """
    rest_client = RestClient(host, port)
    rest_client.login(user, password)
    return rest_client.analytics.time_series_get(
            begin_time=calculate_begin_time(CSV_FILENAME))


def convert_timeseries_into_dict(
    results: Sequence[Mapping[str, Any]]
) -> Mapping[int, Sequence[str]]:
    """
    Extracts important values from the timeseries results into a dictionary,
    keyed by timestamp.
    """

    if not results:
        return {}
    # Setup empty lists for each timestamp
    data = {}
    for timestamp in results[0]['times']:
        data[int(timestamp)] = [None] * len(COLUMNS_TO_PROCESS)

    # Extract each data point
    for series in results:
        name = series['id']
        if name not in COLUMNS_TO_PROCESS:
            continue
        for timestamp, value in zip(series['times'], series['values']):
            column_idx = COLUMNS_TO_PROCESS.index(name)
            data[int(timestamp)][column_idx] = value

    return data


def write_csv_to_file(
    data: Mapping[int, Sequence[str]],
    filename: str
) -> None:
    """Write the provided data to the file, creating headers if needed"""
    with open(filename, 'a') as output_file:
        # Add headers if they don't exist
        if os.path.getsize(filename) == 0:
            columns_csv = ','.join(COLUMNS_TO_PROCESS)
            output_file.write(f'unix.timestamp,gmtime,{columns_csv}\r\n')

        for ts in sorted(data):
            gmt = time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime(ts))
            data_csv = ','.join([str(d) for d in data[ts]])
            output_file.write(f'{ts},{gmt},{data_csv}\r\n')


def main(sys_args: Sequence[str]):
    # args = parse_args(sys_args)
    # results = read_time_series_from_cluster(args.host, args.user, args.password, args.port)

    results = read_time_series_from_cluster("10.44.0.4", "admin", "Admin123", "8000")

    data = convert_timeseries_into_dict(results)
    write_csv_to_file(data, CSV_FILENAME)


if __name__ == '__main__':
    main(sys.argv[1:])