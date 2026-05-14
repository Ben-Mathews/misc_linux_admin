### New Computer Quick-Start
Run this on a new machine to quickly install and configure the way they should be
```shell
cd /tmp && \
wget -O initial_package_installs_26_04.sh "https://raw.githubusercontent.com/Ben-Mathews/misc_linux_admin/refs/heads/master/initial_package_installs_26_04.sh" && \
wget -O firefox_snap_debloat.sh "https://raw.githubusercontent.com/Ben-Mathews/misc_linux_admin/refs/heads/master/firefox_snap_debloat.sh" && \
echo "code code/add-microsoft-repo boolean true" | sudo debconf-set-selections && \
chmod +x initial_package_installs_26_04.sh && \
./initial_package_installs_26_04.sh --force-all
```
Make sure to use or don't use `--force-all` according to needs

