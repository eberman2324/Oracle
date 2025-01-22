{
#    FS="/"
    for (i = 1; i <= NF; i++)
        arr[$i]++
}

END {
    FS="/"
    da_restore="cat hrestrore_batch* |  more"
    for (db_file in arr)
        print db_file da_restore
}


