

The following shows you the list of eval licenses.
---------------------------------------------
What licenses are on my cluster
----------------------------------------------
Dallas-1# isi_gconfig -t licensing
[root] {version:1}
licensing.features.HARDENING.json (char*) = {}\n
licensing.features.SNAPSHOTIQ.json (char*) = {\"evaluation\":{\"evaluated\":true,\"expiration\":1515369600}}\n
licensing.features.ONEFS.json (char*) = {}\n
licensing.features.SMARTQUOTAS.json (char*) = {\"evaluation\":{\"evaluated\":false,\"expiration\":1510704000}}\n
licensing.features.SMARTDEDUPE.json (char*) = {}\n
licensing.features.SWIFT.json (char*) = {}\n
licensing.features.HDFS.json (char*) = {}\n
licensing.features.CLOUDPOOLS.json (char*) = {}\n
licensing.features.SMARTCONNECT_ADVANCED.json (char*) = {\"evaluation\":{\"evaluated\":false,\"expiration\":1510704000}}\n
licensing.features.SMARTPOOLS.json (char*) = {\"evaluation\":{\"evaluated\":false,\"expiration\":1510704000}}\n
licensing.features.SMARTLOCK.json (char*) = {}\n
licensing.features.SYNCIQ.json (char*) = {\"evaluation\":{\"evaluated\":false,\"expiration\":1510704000}}\n
licensing.swid (char*) = <null>
ignore_signature (bool) = false
last_upgrade_commit_epoch (int64) = -1

--------------------------------------------------
Remove a demo license – This removes a specific license
---------------------------------------------------
isi_gconfig -t licensing -R licensing.features.SNAPSHOTIQ.json

---------------------------------------------------
Add a new eval license – Bam you have a new eval license
---------------------------------------------------
isi license add --evaluation=ONEFS
isi license add --evaluation=SMARTCONNECT_ADVANCED
isi license add --evaluation=SMARTDEDUPE
isi license add --evaluation=SMARTLOCK
isi license add --evaluation=SMARTPOOLS
isi license add --evaluation=SMARTQUOTAS
isi license add --evaluation=SNAPSHOTIQ
isi license add --evaluation=SYNCIQ
isi license add --evaluation=CLOUDPOOLS
