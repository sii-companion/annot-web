package 'build-essential'

git '/home/vagrant/genometools' do
  repository 'https://github.com/genometools/genometools.git'
  revision 'master'
  action :sync
end

execute 'install_gt' do
  command "cd /home/vagrant/genometools; make -j2 cairo=no curses=no install"
end
