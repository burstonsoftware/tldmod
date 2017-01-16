sudo apt-get install p7zip tree python

echo HI THERE!

tree -h .

SVNREV=$(git rev-list --count HEAD)

echo Compiling retail revision $SVNREV!

curl https://ccrma.stanford.edu/~craig/utility/flip/flip.cpp -O -J && sudo g++ flip.cpp -o /usr/bin/flip

cd ModuleSystem && sed -i 's/cheat_switch = 1/cheat_switch = 0/' module_constants.py

./build_module.sh
./build_module_wb.sh

cd .. && echo Building revision $SVNREV!

git config --global core.quotepath false
git diff --name-status --diff-filter=ACMRTUXB TLD3.3REL ./ > diff.txt

cat diff.txt | sed -r -e  s/^D.+// \
                      -e 's/.+modulesystem.+//I' \
                      -e 's/.*unused.*//I' \
                      -e 's/.*src.*//I' \
                      -e 's/.*cmd.*//I' \
                      -e 's/.*exe.*//I' \
                      -e 's/.*yml.*//I' \
                      -e 's/.*sh.*//I' \
                      -e 's/.*\.git.*//I' \
                      -e 's/.*\/[\_|\.][^wT][^b].*//' \
                      -e '/^$/d' \
                      -e 's/^.+TLD_GA\///' > diff_mod.txt

mkdir ../TLD

cat ./diff_mod.txt | while read i; do cp --parents "${i:2}" "../TLD/"; done

cd ../TLD
tree -h .

#fixed Linux case-sensitive language files detection
mv Languages languages

cd ..

# make a copy for the warband version
cp -rf TLD TLD_WB

# remove the now unneeded warband subfolder from the TLD dir
rm -rf TLD/_wb

# overwrite the content in the warband version with the files from the _wb subfolder
cp -rf TLD_WB/_wb/* TLD_WB/

#remove the now empty _wb subfolder from the warband version
rm -rf TLD_WB/_wb
rm -f  TLD_WB/Data/mb.fxo

#paste the original optimized warband glsl shaders in GLShadersOptimized
curl https://github.com/tldmod/tldmod/releases/download/TLD3.3REL/vanilla_glsl_opt.zip -L -O
unzip vanilla_glsl_opt.zip -d ./TLD_WB

#move our custom tld shaders into their rightful place
mv TLD_WB/GLShaders/*.glsl TLD_WB/GLShadersOptimized/

tree -h .

#bbfile=TLD_3.3_nightly_patch_r$SVNREV.7z
#bbfilewb=TLD_3.3_wbcompat_nightly_patch_r$SVNREV.7z
bbfile=TLD_3.3_nightly_patch_$(date +%Y.%m.%d-%H.%M -u)_r$SVNREV.7z
bbfilewb=TLD_3.3_wbcompat_nightly_patch_$(date +%Y.%m.%d-%H.%M -u)_r$SVNREV.7z

# a small notice
echo -e "This release has been churned out by an automated process, generated directly from our dev repository at revision $SVNREV,\r\n\
that doesn't mean it has to be broken, but *may* not work as well as a stable release due to lack of testing and other things.\r\n\
\r\n\
They have not been supervised by a real person, treat them as such. Also, have fun! :)\r\n\
\r\n\
--swyter\r\n\
\r\n\
PS: For more info and official support/updates take a look to <https://tldmod.github.io> and <http://moddb.com/mods/the-last-days>" > notice

cp notice "THIS IS AN AUTOMATED RELEASE OF TLD FOR M&B 1.011, REVISION $SVNREV"
cp notice "THIS IS AN AUTOMATED RELEASE OF TLD FOR WARBAND, REVISION $SVNREV"


7zr a -mx9 -r -y $bbfile TLD "THIS IS AN AUTOMATED RELEASE OF TLD FOR M&B 1.011, REVISION $SVNREV"

rm -rf TLD
mv TLD_WB TLD

7zr a -mx9 -r -y $bbfilewb TLD "THIS IS AN AUTOMATED RELEASE OF TLD FOR WARBAND, REVISION $SVNREV"

curl https://bitbucket.org/Swyter/bitbucket-curl-upload-to-repo-downloads/raw/default/upload-to-bitbucket.sh -O -J
chmod +x ./upload-to-bitbucket.sh

ls -ra

sh ./upload-to-bitbucket.sh $bbuser $bbpass $bbpage "$bbfile"
sh ./upload-to-bitbucket.sh $bbuser $bbpass $bbpage "$bbfilewb"