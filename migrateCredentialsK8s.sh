#! /bin/bash

if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found"
    exit 1
fi

GEN_DIR=gen
mkdir -p $GEN_DIR
#rm -Rf $GEN_DIR/*

# EXPORT FOLDER CREDENTIALS
echo "------------------  EXPORT FOLDER CREDENTIALS  ------------------"
curl -o $GEN_DIR/export-credentials-folder-level.groovy https://raw.githubusercontent.com/cloudbees/jenkins-scripts/master/credentials-migration/export-credentials-folder-level.groovy
curl --data-urlencode "script=$(cat $GEN_DIR/export-credentials-folder-level.groovy)" \
--user $TOKEN_SOURCE ${CONTROLLER_SOURCE_URL}/scriptText  -o $GEN_DIR/tmp-folder.txt
tail -n 1  $GEN_DIR/tmp-folder.txt | sed  -e "s#\[\"##g"  -e "s#\"\]##g"  | tee  $GEN_DIR/folder-imports.txt

# IMPORT FOLDER CREDENTIALS
echo "------------------  IMPORT FOLDER CREDENTIALS  ------------------"
kubectl cp $GEN_DIR/folder-imports.txt ${TARGET_POD}:/var/jenkins_home/ -n $NAMESPACE
curl -o $GEN_DIR/update-credentials-folder-level.groovy https://raw.githubusercontent.com/cloudbees/jenkins-scripts/master/credentials-migration/update-credentials-folder-level.groovy
cat $GEN_DIR/update-credentials-folder-level.groovy | sed  "s#^\/\/ encoded.*#encoded = [new File(\"/var\/jenkins_home\/folder-imports.txt\").text]#g" >  $GEN_DIR/mod-update-credentials-folder-level.groovy
# Fix remove new line
#cat $GEN_DIR/mod-update-credentials-folder-level.groovy sed -e '/\/\/ encoded = \[new File(\"\/home\/jenkins\/system_credentials.txt\"\).text\]/a\encoded=encoded.collect { it.replaceAll(/\\r?\\n/, "") }' > $GEN_DIR/mod1-update-credentials-folder-level.groovy
# end Fix
curl -v --data-urlencode "script=$(cat $GEN_DIR/mod1-update-credentials-folder-level.groovy)" \
--user $TOKEN_TARGET ${CONTROLLER_TARGET_URL}/scriptText

# EXPORT SYSTEM CREDENTIALS
echo "------------------  EXPORT SYSTEM CREDENTIALS  ------------------"
curl -o $GEN_DIR/export-credentials-system-level.groovy https://raw.githubusercontent.com/cloudbees/jenkins-scripts/master/credentials-migration/export-credentials-system-level.groovy
curl --data-urlencode "script=$(cat $GEN_DIR/export-credentials-system-level.groovy)" \
--user $TOKEN_SOURCE ${CONTROLLER_SOURCE_URL}/scriptText  -o $GEN_DIR/tmp-system-credentials.txt
tail -n 1  $GEN_DIR/tmp-system-credentials.txt | sed  -e "s#\[\"##g"  -e "s#\"\]##g"  | tee  $GEN_DIR/system-imports.txt

#cat $GEN_DIR/system-imports.txt | awk '{ while (length($0) % 4 != 0) $0 = $0 "="; print }' |tee $GEN_DIR/tmp-system-credentials.txt
#diff  $GEN_DIR/system-imports.txt $GEN_DIR/tmp-system-credentials.txt


# IMPORT SYSTEM CREDENTIALS
echo "-------------------- IMPORT SYSTEM CREDENTIALS  ------------------"
kubectl cp $GEN_DIR/system-imports.txt ${TARGET_POD}:/var/jenkins_home/  -n $NAMESPACE
curl -o $GEN_DIR/update-credentials-system-level.groovy https://raw.githubusercontent.com/cloudbees/jenkins-scripts/master/credentials-migration/update-credentials-system-level.groovy
cat $GEN_DIR/update-credentials-system-level.groovy | sed  "s#^\/\/ encoded.*#encoded = [new File(\"/var\/jenkins_home\/system-imports.txt\").text]#g" >  $GEN_DIR/mod-update-credentials-system-level.groovy
# Fix remove new line
#cat $GEN_DIR/mod-update-credentials-system-level.groovy sed -e '/\/\/ encoded = \[new File(\"\/home\/jenkins\/system_credentials.txt\"\).text\]/a\encoded=encoded.collect { it.replaceAll(/\\r?\\n/, "") }' > $GEN_DIR/mod1-update-credentials-system-level.groovy
# End fix
curl -v --data-urlencode "script=$(cat $GEN_DIR/mod1-update-credentials-folder-level.groovy)" \
--user $TOKEN_TARGET ${CONTROLLER_TARGET_URL}/scriptText

#reload new Jobs from disk
curl -L -s -u $TOKEN_TARGET -XPOST  "${CONTROLLER_TARGET_URL}/reload"
