
git '/home/vagrant/annot-nf' do
  repository 'https://github.com/sanger-pathogens/annot-nf'
  revision 'master'
  action :sync
end

directory "/home/vagrant/annot-nf" do
  owner "vagrant"
  group "vagrant"
  recursive true
end

execute 'pull_image' do
  command "docker pull satta/annot-nf"
end
