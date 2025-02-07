#!/bin/sh

APPNAME=__appname__
VERSION=__version__
PREFIX=/opt/$APPNAME-$VERSION

THIS=$0
SKIP=`awk '/^__END_SCRIPT_TAG__$/ { print NR + 1; exit 0; }' "$THIS"` 


help() {
cat << EOF
$1 <cmd> [cmd args]

  Available commands as <cmd> :

    install : install application $APPNAME $VERSION
      optionnal arg : installation path. Default installation path is
      $PREFIX

    extract : extract embedded tar gz archive as $APPNAME-$VERSION.bin.tar.gz
      optionnal arg : alternate target file

    help : display help info

  Exemples : 

    to install application to its default location just enter followin command
      $1 install

    to extract embedded archive as archive.tar.gz :
      $1 extract archive.tar.gz
EOF
exit 0
}
ME
install() {
	if [ $# -eq 1 ]
	then
		PREFIX="$1"
	fi
	echo "Welcome to $APPNAME $VERSION installation."
	if [ -r "$PREFIX" ]
	then
		echo "Warning: target directory already exists. Continue (y/n) ?"
		read rep
		if [ "$rep" != "y" -a "$rep" != "Y" ]
		then
			exit 1
		fi
	else
		mkdir -p "$PREFIX" 
	fi

	if [ ! -w "$PREFIX" ]
	then
		echo "Can't create installation path. Check path or gain required write access."
		exit 2
	fi

	TEMPDIR="$PREFIX/bs-install.$$"
	mkdir -p "$TEMPDIR"
	tail -n +$SKIP "$THIS" | tar -xvz -C "$TEMPDIR"
	mv "$TEMPDIR"/$APPNAME-$VERSION/* "$PREFIX"
	mv "$TEMPDIR"/$APPNAME-$VERSION/.* "$PREFIX" 2> /dev/null # we silence errors for . and ..
	rm -rf "$TEMPDIR"
    
    # fix tar extract preserving original uid/gid when extracting as root
    uid=`id -u`
    [ $uid -eq 0 ] && chown -R 0:0 "$PREFIX"

    # update .env file with actual install path
    env_file=$PREFIX/.env
    if [ -f "$env_file" ]; then
        abs_prefix=`readlink -f $PREFIX`
        mv $env_file ${env_file}.bak
        [ -z "$abs_prefix" ] && abs_prefix=$PREFIX
        echo "INSTALL_DIR=$abs_prefix" > $env_file
        cat ${env_file}.bak >> ${env_file}
        rm -f ${env_file}.bak
    fi
	postinstall_script="bin/postinstall_${APPNAME}.sh"
    [ ! -x "$PREFIX/${postinstall_script}" ] && postinstall_script="bin/postinstall.sh"

	if [ -x "$PREFIX/${postinstall_script}" ]
	then
		( cd "$PREFIX" && exec "${postinstall_script}" "$APPNAME" "$VERSION" )
	fi
	echo "Installation completed."
}

extract() {
	target=$APPNAME-$VERSION.bin.tar.gz
	if [ $# -eq 1 ]
	then
		target="$1"
	fi
	if [ -f "$target" ]
	then
		echo "Warning: target file already exists. Continue (y/n) ?"
		read rep
		if [ "$rep" != "y" -a "$rep" != "Y" ]
		then
			exit 1
		fi
	fi
	tail -n +$SKIP "$THIS" > "$target"
	echo "Extraction completed."
}


if [ $# -eq 0 ]
then
	help $0
fi

case "$1" in
	install|extract) 
		"$@"
		;;
	*)
		help $0
		;;
esac

exit 0
__END_SCRIPT_TAG__
