require 'json'
require 'socket'

class Struct
	def to_map
		map = Hash.new
		self.members.each {|m| map[m] = self[m]}
		map
	end

	def to_json(*x)
		to_map.to_json(*x)
	end
end

def hostname
	{:Hostname => Socket.gethostname}.to_json
end

def ip_addresses
	ips = Array.new
	Socket.ip_address_list.each do |addr_info|
	 	if addr_info.ipv4? and !addr_info.ipv4_loopback? and !addr_info.ipv4_multicast?
	 		ips.push(addr_info.ip_address)
	 	end
	end
	ips.to_json
end

# yes, I realize it would have been a gazillion times simpler by using hashes instead of structs.. but oh well..

Struct.new("CPU", :Processors, :ModelName, :Speed, :Load1, :Load5, :Load15, :Processes)
def cpu
	processors = %x[cat /proc/cpuinfo | grep -c '^processor'].strip
	model_name = %x[cat /proc/cpuinfo | grep '^model name' | head -n 1 | awk -F: '{print $2;}'].strip
	speed = %x[cat /proc/cpuinfo | grep '^cpu MHz' | head -n 1 | awk -F: '{print $2;}'].strip
	loadavg = %x[cat /proc/loadavg | awk '{print $1";"$2";"$3";"$4;}'].strip.split(";")

	Struct::CPU.new(processors, model_name, speed, loadavg[0], loadavg[1], loadavg[2], loadavg[3]).to_json
end

Struct.new("MemoryData", :TotalM, :TotalH, :UsedM, :UsedH, :FreeM, :FreeH)
# Struct.new("Memory", :RAM, :Swap, :Total)
def mem
	# memory = Hash.new(Struct::MemoryData.new(0,"0",0,"0",0,"0"))
	memory = Hash.new

	mdata = %x[free -otm | awk '{print $1";"$2";"$3";"$4;}'].strip.split("\n")
	mem_parse_m(memory, mdata)

	hdata = %x[free -oth | awk '{print $1";"$2";"$3";"$4;}'].strip.split("\n")
	mem_parse_h(memory, hdata)

	memory.to_json
end

def mem_parse_m(memory, data)
	mem_fill_m(memory,"RAM",data[1])
	mem_fill_m(memory,"Swap",data[2])
	mem_fill_m(memory,"Total",data[3])
end

def mem_parse_h(memory, data)
	mem_fill_h(memory,"RAM",data[1])
	mem_fill_h(memory,"Swap",data[2])
	mem_fill_h(memory,"Total",data[3])
end

def mem_fill_m(memory,type,line)
	values = line.split(";")
	data = memory.key?(type) ? memory[type] : Struct::MemoryData.new(0,"0",0,"0",0,"0")
	data.TotalM = values[1]
	data.UsedM = values[2]
	data.FreeM = values[3]
	memory[type] = data
end

def mem_fill_h(memory,type,line)
	values = line.split(";")
	data = memory.key?(type) ? memory[type] : Struct::MemoryData.new(0,"0",0,"0",0,"0")
	data.TotalH = values[1]
	data.UsedH = values[2]
	data.FreeH = values[3]
	memory[type] = data
end

Struct.new("DiskUsage", :Filesystem, :Size, :Used, :Available, :UsagePercentage, :MountedOn)
def df
	disks = Array.new
	%x[df -h | awk '{print $1";"$2";"$3";"$4";"$5";"$6;}'].strip.split("\n").each do |disk|
		values = disk.split(";")
		disks.push(Struct::DiskUsage.new(values[0], values[1], values[2], values[3], values[4].tr('%',''), values[5]))
	end
	disks.to_json
end

Struct.new("Process", :User, :Pid, :Cpu, :Mem, :Vsz, :Rss, :Tty, :Stat, :Start, :Time, :Command)
def top
	data = Hash.new

	header = Array.new
	%x[top -b -n 1 2>/dev/null | head -n 5].strip.split("\n").each do |process|
		header.push(process.strip)
	end
	data["Header"] = header

	processes = Array.new
	%x[ps -aux | tail -n +2 | grep -v 'ps -aux' | sort -nr -k6].strip.split("\n").each do |process|
		process =~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.*)$/
		processes.push(Struct::Process.new($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11.strip))
	end
	data["Processes"] = processes

	data.to_json
end

Struct.new("LoggedOn", :User, :TTY, :From, :Login, :Idle, :JCPU, :PCPU, :What)
def logged_on
	users = Array.new
	%x[PROCPS_USERLEN=24 PROCPS_FROMLEN=64 w -ih | grep -v 'w -ih'].strip.split("\n").each do |user|
		user =~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.*)$/
		users.push(Struct::LoggedOn.new($1, $2, $3, $4, $5, $6, $7, $8))
	end
	users.to_json
end

Struct.new("User", :Type, :Name, :Description, :Home, :Shell)
def passwd
	users = Array.new
	%x[awk -F: '{ if ($3<=499) print "system;"$1";"$5";"$6";"$7; else print "user;"$1";"$5";"$6";"$7; }' /etc/passwd].strip.split("\n").each do |user|
		values = user.split(";")
		users.push(Struct::User.new(values[0], values[1], values[2], values[3], values[4]))
	end
	users.to_json
end

Struct.new("If", :Name, :Type, :Value)
def network
	ifs = Array.new
	%x[ip -o addr | awk '{print $2";"$3";"$4;}'].strip.split("\n").each do |interface|
		values = interface.split(";")
		ifs.push(Struct::If.new(values[0], values[1], values[2]))
	end
	ifs.to_json
end
