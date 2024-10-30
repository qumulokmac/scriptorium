    fs_copy             Server-side copy a file.
    fs_create_dir       Create a new directory
    fs_create_file      Create a new file
    fs_create_link      Create a new link
    fs_create_symlink   Create a new symbolic link
    fs_create_unix_file
                        Create a new pipe, character device, block device or socket
    fs_delete           Delete a file system object
    fs_delete_user_metadata
                        Delete the user metadata for a file by using the specified metadata key
    fs_file_get_attr    Get file attributes
    fs_file_samples     Get a number of sample files from the file system
    fs_file_set_attr    Set file attributes
    fs_file_set_smb_attrs
                        Change SMB extended attributes on the file
    fs_get_acl          Get file ACL
    fs_get_atime_settings
                        Get access time (atime) settings.
    fs_get_notify_settings
                        Get FS notify settings.
    fs_get_permissions_settings
                        Get permissions settings
    fs_get_stats        Get file system statistics
    fs_get_user_metadata
                        Retrieve a user metadata value for a file by using the specified metadata key
    fs_hash_md5         Generate an MD5 hash of a file/named stream's contents
    fs_list_lock_waiters_by_client
                        List waiting lock requests for a particular client machine
    fs_list_lock_waiters_by_file
                        List waiting lock requests for a particular file
    fs_list_locks       List file locks held by clients.
    fs_list_named_streams
                        List all named streams on file or directory
    fs_list_user_metadata
                        Retrieve user metadata of the specified type for a file
    fs_modify_acl       Modify file ACL
    fs_notify           Notify on changes to files and directories under the specified directory. To cancel the listener, send a SIGQUIT signal (press CTRL+D).
    fs_punch_hole       Create a hole in a region of a file. Destroys all data within the hole.
    fs_read             Read an object
    fs_read_dir         Read directory
    fs_read_dir_aggregates
                        Read directory aggregation entries
    fs_release_nlm_lock
                        Release an arbitrary NLM byte-range lock range. This is dangerous, and should only be used after confirming that the owning process has leaked the lock, and only if there is a very good
                        reason why the situation should not be resolved by terminating that process.
    fs_release_nlm_locks_by_client
                        Release NLM byte range locks held by client. This method releases all locks held by a particular client. This is dangerous, and should only be used after confirming that the client is
                        dead.
    fs_remove_stream    Remove a stream from file or directory
    fs_rename           Rename a file system object
    fs_resolve_paths    Resolve file IDs to paths
    fs_security_add_key
                        Add a key to the file system key-store.
    fs_security_delete_key
                        Delete a key from the file system key store.
    fs_security_get_key
                        Get information for a key in the file system key store.
    fs_security_get_key_replace_challenge
                        Get a security challenge for replacing the specified key without affecting the snapshots and snapshot policies associated with it.
    fs_security_get_key_usage
                        Show information about snapshot and snapshot policy usage for a key from the file system key store.
    fs_security_list_keys
                        List information for all keys in the file system key store.
    fs_security_modify_key
                        Modify the name or comment of a key in the file system key store. Enable or disable a key.
    fs_security_replace_key
                        Replace the specified key without affecting the snapshots and snapshot policies associated with it.
    fs_set_acl          Set file ACL
    fs_set_atime_settings
                        Set access time (atime) settings.
    fs_set_notify_settings
                        Set FS notify settings
    fs_set_permissions_settings
                        Set permissions settings
    fs_set_user_metadata
                        Set or update a user metadata value for a file by using the specified metadata key and value
    fs_walk_tree        Walk file system tree
    fs_write            Write data to an object