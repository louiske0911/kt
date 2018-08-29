#!/bin/bash
source lib/config.sh
source lib/install.sh
source lib/makefile.sh
source lib/unittest.sh

#######################################################
#              Ktfff Unittest Runner                  #
#                                                     #
#   install         - install ktf framework           #
#   run             - build && run all unittest       #
#   run --test=     - build && run single unittest    #
#   run --suite=    - build && run single unittest    #
#   clean           - clean all generated file        #
#                                                     #
#######################################################

#######################################################
#               Runner Flow                           #
#######################################################

function clean_env()
{
    ktfff_info "KTFFF CLEAN"
    find $KTFFF_DIR/../ -type f -name "*.o.*" -delete
    find $KTFFF_DIR/../ -type f -name ".*.cmd" -delete
    find $KTFFF_DIR/../ -type f -name "*.o" -delete
    sudo /bin/rm -rf *.symvers *.mod.c Module.markers modules.order .tmp_versions *.xml
    sudo /bin/rm -rf *.ko
    sudo /bin/rm -rf Makefile
    sudo /bin/rm -rf $unitM_temp_dir
    sudo /bin/rm -rf $unitMK_temp_dir
    sudo /bin/rm -rf $unit_output_dir
}

function ktfff_info()
{
    local info_str=$1
    Col='\e[0m'
    BIBlu='\e[0;96m'
    printf "\n${BIBlu}[INFO] ${Col}$info_str \n"
}

function ktfff_error()
{
    local error_str=$1
    Col='\e[0m'
    BIBlu='\e[1;95m'
    printf "\n${BIBlu}[ERR] ${Col}$error_str \n"
}


function ktfff_insmod()
{   
    cmd_err=$(sudo insmod $BUILD_DIR/ktf/kernel/ktf.ko)
    if [[ $cmd_err = *"No such file or directory"* ]]; then
        echo "Should execute sudo ./ktfff.sh install first." 
    fi
}

function unittest_main()
{
    local suite_list=
    local filter=""

    mkdir -p $unitM_temp_dir
    mkdir -p $unitMK_temp_dir
    mkdir -p $unit_output_dir

    # build_user_daemon?

    # If options exist --test, --suite, if not will run all ./unittests/files
    if [ $# -gt 0 ]; then
        set -e 
        suite_list=$(unittest_check_build_file $@)
        filter=$(unittest_get_filter $@)
        
        ktfff_info "BUILDING KERNEL MODULE"
        build_all_kern_module $suite_list
        set +e
    else
        ktfff_info "BUILDING KERNEL MODULE"
        build_all_kern_module $KTFFF_DIR/unittests/*.c
    fi

    ktfff_insmod
    ktfff_info "UNNITEST START"
    unittest_start $filter
    ktfff_info "UNNITEST COMPLETE"
}

export LANG=en_US


# --- Command line help -------------------------------------------
function usage()
{
    echo -e "\nUsage: $0 [argument...]"
    echo
    echo -e "  install                      install ktfff runnner (gtest, ktf)."
    echo -e "  run                          build all kernel module and run all unittest case."
    echo -e "  run --test=<testcase>        build specific kernel module and run specific unittest case."
    echo -e "  run --suite=<testfile.c>     build specific kernel module and run specific unittest file."
    echo -e "  clean                        remove all file generated by ktfff."
    echo -e "  -h, --help                   display this help text and exit."
    echo
    exit 1
}

# --- Ktfff main --------------------------------------------------
while [ "$#" ]; do
    case $1 in
        install )
            shift
            ktfff_info "KTFFF INSTALL\n"
            ktfff_setup
            exit
            ;;
        run )
            shift
            unittest_main $@
            exit
            ;;
        clean )
            shift
            clean_env
            exit
            ;;
        -h | --help )
            usage
            ;;
        * )
            usage
    esac
    shift
done 
