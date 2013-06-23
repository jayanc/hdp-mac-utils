#!/bin/sh

# Set parameters
APP_DIR=`dirname $0`
CUR_DIR=`pwd`

cd $APP_DIR
. ./mac_env.sh

if [ $# -ne 1 ]; then
	echo "Usage: expand_link.sh $STAGE_DIR"
else
	SOURCE_DIR=$1
	cat $APP_DIR/hdp_artifacts.txt | while read next; do
		T_FILE=`echo $next | awk '{print $1}'`
		T_LINK=`echo $next | awk '{print $2}'`
		
		cd $LIB_BASE_DIR
		if [ ! -d $HDP_VER ]; then
			sudo mkdir $HDP_VER	
		fi
		
		echo "Reseting: $T_LINK libraries and links"
		sudo rm -rf $HDP_VER/$T_FILE $T_LINK
		cd $HDP_VER
		sudo tar xzf $SOURCE_DIR/$T_FILE.tar.gz
		cd $LIB_BASE_DIR
		sudo ln -s $HDP_VER/$T_FILE $T_LINK

	done
	
	# Link JDBC drivers
	cat $APP_DIR/jdbc_cfg.txt | while read next; do
		J_FILE=`echo $next | awk '{print $1}'`
		J_LINK=`echo $next | awk '{print $2}'`
		
		echo "Set jdbc link: $J_FILE -> J_LINK"
		sudo ln -s $J_FILE $LIB_BASE_DIR/hive/lib/$J_LINK
	done

	# Expand the Defaults
	if [ ! -d $DEFAULT_DIR ]; then
		echo "Creating: $DEFAULT_DIR"
		sudo mkdir -p $DEFAULT_DIR	
	fi	

	cd $DEFAULT_DIR
	
	echo "Expanding defaults"
	sudo tar xzf $SOURCE_DIR/$DEFAULT_FILES.tar.gz
	echo "default complete"
	
	# Expand the Templates and Link
	# DON'T OVERWRITE IF THEY ARE THERE ALREADY
	if [ -d $HADOOP_CONF_DIR/core_hadoop ]; then
		echo "Configs are already present, they have NOT been overwritten"
	else
		cd $SOURCE_DIR
		if [ ! -f $COMPANION_FILE ]; then
			echo "Expanding companion files"
			tar xzf $COMPANION_FILE.tar.gz
		fi	
			
		cd $COMPANION_FILE/configuration_files
		cp -R * $HADOOP_CONF_DIR

		echo "NOTICE: You MUST now edit all the appropriate configs in the $HADOOP_CONF_DIR directory for your environment."
		echo "	You need to change settings in:"
		echo "		core_hadoop, hive, oozie, pig, sqoop, webhcat, zookeeper"
		echo ""
		echo "  Review the configs in these directories and configure for -localhost-"
		
		echo ""
		echo ""
		echo "Setting up config links"
		# Link configs to standard location know by scripts
		if [ ! -d /etc/hadoop ]; then
			sudo mkdir /etc/hadoop
		fi
		if [ ! -d /etc/hbase ]; then
			sudo mkdir /etc/hbase
		fi
		if [ ! -d /etc/hive ]; then
			sudo mkdir /etc/hive
		fi
		if [ ! -d /etc/oozie ]; then
			sudo mkdir /etc/oozie
		fi
		if [ ! -d /etc/pig ]; then
			sudo mkdir /etc/pig
		fi
		if [ ! -d /etc/sqoop ]; then
			sudo mkdir /etc/sqoop
		fi
		if [ ! -d /etc/webhcat ]; then
			sudo mkdir /etc/webhcat
		fi
		if [ ! -d /etc/zookeeper ]; then
			sudo mkdir /etc/zookeeper
		fi
		#TODO: NEED VALIDATION ON FLUME CONFIGURATION
		if [ ! -d /etc/flume ]; then
			sudo mkdir /etc/flume
		fi
	fi

	# Remove old symlinks
	sudo rm /etc/hadoop/conf
	sudo rm /etc/hbase/conf
	sudo rm /etc/hive/conf
	sudo rm /etc/oozie/conf
	sudo rm /etc/pig/conf
	sudo rm /etc/sqoop/conf
	sudo rm /etc/webhcat/conf
	sudo rm /etc/zookeeper/conf

	# Set/Reset symlinks
	sudo ln -s $HADOOP_CONF_DIR/core_hadoop /etc/hadoop/conf
	sudo ln -s $HADOOP_CONF_DIR/hbase /etc/hbase/conf
	sudo ln -s $HADOOP_CONF_DIR/hive /etc/hive/conf
	sudo ln -s $HADOOP_CONF_DIR/oozie /etc/oozie/conf
	sudo ln -s $HADOOP_CONF_DIR/pig /etc/pig/conf
	sudo ln -s $HADOOP_CONF_DIR/sqoop /etc/sqoop/conf
	sudo ln -s $HADOOP_CONF_DIR/webhcat /etc/webhcat/conf
	sudo ln -s $HADOOP_CONF_DIR/zookeeper /etc/zookeeper/conf

	echo "  === DONE: Don't forget to adjust your configs for 'localhost'"
fi
