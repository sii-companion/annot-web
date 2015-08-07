package 'curl'

execute 'install_nextflow' do
  not_if { File.exist?("/home/vagrant/nextflow") }
  command "cd /home/vagrant; curl -fsSL get.nextfl`ow.io | bash"
end

file '/home/vagrant/nextflow' do
  mode '0755'
end