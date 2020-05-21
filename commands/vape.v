module main

import cli
import os

fn main() {
	mut vape := cli.Command{
		name: 'vape'
		description: 'The Vape Web Microframework Command-line Helper'
		version: '0.2.0'
		parent: 0
	}
	vape.add_command(cli.Command{
		name: 'init'
		description: 'Creates a bare project'
		execute: init_handler
		parent: 0
	})
	vape.add_command(cli.Command{
		name: 'dev'
		description: 'Compiles a development build and runs it'
		execute: dev_handler
		parent: 0
	})
	vape.parse(os.args)
}

fn init_handler(cmd cli.Command) {
	// Before anything, check that V is installed…
	if os.system('which v > /dev/null') == 1 {
		println('🧨 V is not installed. Exiting.')
		return
	}
	// Also, vape is needed in addition to the executable
	if !os.is_dir('${os.home_dir()}/.vmodules/exastencil/vape') {
		println('🧨 Vape is not installed. Install it with `v install exastencil.vape`')
		return
	}
	// Then, check that the folder is writable
	os.is_writable_folder('.') or {
		println('🧨 Folder is not writable. Exiting.')
		return
	}
	// Set up a basic gitignore if one isn't present
	print('📄 Checking for a gitignore…')
	os.flush()
	if os.exists('.gitignore') {
		println(' found!')
	} else {
		print(' missing… creating…')
		os.flush()
		os.write_file('.gitignore', '# Keep only source code in endpoints\n/endpoints/**\n!/endpoints/**/*.v\n# Ignore build artifacts\n/build')
		println(' done!')
	}
	// Create endpoints folder with example if empty
	print('🎯 Checking for endpoints folder…')
	os.flush()
	if !os.exists('endpoints') {
		print(' missing… creating…')
		os.flush()
		os.mkdir('endpoints') or {
			return
		}
		print(' adding sample…')
		os.flush()
		os.write_file('endpoints/hello.v', "import net.http\n\n['/hello']\nfn hello(req http.Request) http.Response {\n\treturn http.Response{\n\t\theaders: {\n\t\t\t'Content-Type': 'text/plain'\n\t\t}\n\t\ttext: 'Hello World'\n\t\tstatus_code: 200\n\t}\n}\n")
		println(' done!')
	} else if os.is_dir('endpoints') && os.is_dir_empty('endpoints') {
		print(' found empty… adding sample…')
		os.flush()
		os.write_file('endpoints/hello.v', "import net.http\n\n['/hello']\nfn hello(req http.Request) http.Response {\n\treturn http.Response{\n\t\theaders: {\n\t\t\t'Content-Type': 'text/plain'\n\t\t}\n\t\ttext: 'Hello World'\n\t\tstatus_code: 200\n\t}\n}\n")
		println(' done!')
	} else {
		println(' found!')
	}
}

fn dev_handler(cmd cli.Command) {
	println('🔪 Dissecting handlers…')
	// Build three separate sections for the dev server file
	mut imports := ['import exastencil.vape']
	mut handlers := []string{}
	mut endpoints := []string{}
	// Split and merge all endpoints into these sections
	mut current_path := ''
	for path in os.walk_ext('endpoints', 'v') {
		lines := os.read_lines(path) or {
			continue
		}
		for line in lines {
			if line.starts_with('import') {
				if line in imports {
				} else {
					imports << line
				}
			} else if line.starts_with('[') {
				current_path = line.trim('[]')
			} else if line.starts_with('fn ') {
				handler_name := line.split(' ')[1].split('(')[0]
				handlers << line
				endpoints << '\t\tvape.Endpoint{\n\t\t\tpath: $current_path\n\t\t\thandler: $handler_name\n\t\t},'
				current_path = ''
			} else {
				handlers << line
			}
		}
		println('   ↜ $path')
	}
	println('')
	if !os.exists('build') {
		os.mkdir('build') or {
			return
		}
	}
	mut output := os.create('build/dev.v') or {
		println('🧨 Failed to create dev.v. Exiting.')
		return
	}
	output.writeln('// Imports')
	for item in imports {
		output.writeln(item)
	}
	output.writeln('\n// Handlers')
	for line in handlers {
		output.writeln(line)
	}
	output.writeln('\n// Server')
	output.writeln('server := vape.Server{\n\tport: 6789\n\tendpoints: [')
	for item in endpoints {
		output.writeln(item)
	}
	output.writeln('\t]\n}\nserver.serve()')
	output.close()
	println('🧠 Compiling development server…')
	os.exec('v build/dev.v') or {
		println('🧨 Failed to compile development build. Check dev.v for problems or report it.')
		return
	}
	println('🚀 Launching development server on port 6789… Ctrl + C to exit.')
	os.system('build/dev')
}
