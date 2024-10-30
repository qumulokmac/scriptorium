

https://10.8.12.108/api/storage/volumes/${UUID}?fields=space


[ec2-user@ip-172-31-13-123 ~]$ curl --insecure --user "vsadmin:DrunkenQueenHides37" https://172.31.14.117/api/storage/volumes/${UUID}?fields=space
{
  "records": [
    {
      "uuid": "9c629070-9b66-11ed-bc85-09be6cae7799",
      "name": "svm101_root",
      "space": {
        "size": 1073741824,
        "available": 1019252736,
        "used": 802816,
        "block_storage_inactive_user_data": 0,
        "capacity_tier_footprint": 0,
        "performance_tier_footprint": 16330752,
        "local_tier_footprint": 1084747776,
        "footprint": 7725056,
        "over_provisioned": 0,
        "metadata": 11005952,
        "total_footprint": 1084747776,
        "delayed_free_footprint": 8605696,
        "volume_guarantee_footprint": 1057411072,
        "user_data": 45056,
        "used_by_afs": 802816,
        "available_percent": 99,
        "afs_total": 1020055552,
        "full_threshold_percent": 98,
        "nearly_full_threshold_percent": 95,
        "overwrite_reserve": 0,
        "overwrite_reserve_used": 0,
        "size_available_for_snapshots": 1066016768,
        "percent_used": 0,
        "fractional_reserve": 100,
        "block_storage_inactive_user_data_percent": 0,
        "physical_used_percent": 1,
        "physical_used": 7725056,
        "expected_available": 1019252736,
        "filesystem_size": 1073741824,
        "filesystem_size_fixed": false,
        "logical_space": {
          "reporting": false,
          "enforcement": false,
          "used_by_afs": 802816,
          "used_percent": 0,
          "used": 802816,
          "used_by_snapshots": 14139392
        },
        "snapshot": {
          "used": 6922240,
          "reserve_percent": 5,
          "autodelete_enabled": false,
          "reserve_size": 53686272,
          "space_used_percent": 13,
          "reserve_available": 46764032,
          "autodelete_trigger": "volume"
        }
      },
      "_links": {
        "self": {
          "href": "/api/storage/volumes/9c629070-9b66-11ed-bc85-09be6cae7799"
        }
      }
    },
    {
      "uuid": "b3ee4551-9b68-11ed-ad36-69547adf3c62",
      "name": "volmpshare01",
      "space": {
        "size": 1099511627776,
        "available": 915990671360,
        "used": 5458804736,
        "capacity_tier_footprint": 0,
        "performance_tier_footprint": 6622314496,
        "local_tier_footprint": 6734999552,
        "footprint": 5458804736,
        "over_provisioned": 178062155776,
        "metadata": 112685056,
        "total_footprint": 6734999552,
        "delayed_free_footprint": 1163509760,
        "volume_guarantee_footprint": 0,
        "auto_adaptive_compression_footprint_data_reduction": 612954112,
        "effective_total_footprint": 6122045440,
        "user_data": 5243867136,
        "used_by_afs": 5458804736,
        "available_percent": 87,
        "afs_total": 1044536049664,
        "full_threshold_percent": 98,
        "nearly_full_threshold_percent": 95,
        "overwrite_reserve": 0,
        "overwrite_reserve_used": 0,
        "size_available_for_snapshots": 915990667264,
        "percent_used": 0,
        "fractional_reserve": 0,
        "physical_used_percent": 0,
        "physical_used": 5458804736,
        "expected_available": 1039077244928,
        "filesystem_size": 1099511627776,
        "filesystem_size_fixed": false,
        "logical_space": {
          "reporting": false,
          "enforcement": false,
          "used_by_afs": 8225906688,
          "used_percent": 1,
          "used": 8225906688,
          "used_by_snapshots": 0
        },
        "snapshot": {
          "used": 0,
          "reserve_percent": 5,
          "autodelete_enabled": false,
          "reserve_size": 54975578112,
          "space_used_percent": 0,
          "reserve_available": 0,
          "autodelete_trigger": "volume"
        }
      },
      "_links": {
        "self": {
          "href": "/api/storage/volumes/b3ee4551-9b68-11ed-ad36-69547adf3c62"
        }
      }
    }
  ],
  "num_records": 2,
  "_links": {
    "self": {
      "href": "/api/storage/volumes/?fields=space"
    }
  }
}
