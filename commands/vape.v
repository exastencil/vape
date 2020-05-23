module main

import exastencil.vape
import cli
import os

const (
	sample_endpoint = "import exastencil.vape

server.mount('GET', '/', fn (req vape.Request) vape.Response {
	return vape.Response{
		body: 'Hello World'
	}
})
"
	sample_gitignore = '# Keep only source code in endpoints
/endpoints/**
!/endpoints/**/*.v
# Ignore build artifacts
/build'
)

fn main() {
	mut vape := cli.Command{
		name: 'vape'
		description: 'The Vape Web Microframework Command-line Helper'
		version: vape.version
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
	check_v()
	check_vape()
	check_writable()
	setup_gitignore()
	setup_endpoints()
}

fn dev_handler(cmd cli.Command) {
	check_v()
	check_vape()
	check_writable()
	merge()
	compile()
	launch()
}

fn check_v() {
	if os.system('which v > /dev/null') == 1 {
		println('🧨 V is not installed. Exiting.')
		exit(1)
	}
}

fn check_vape() {
	if !os.is_dir('${os.home_dir()}/.vmodules/exastencil/vape') {
		println('🧨 Vape is not installed. Install it with `v install exastencil.vape`')
		exit(1)
	}
}

fn check_writable() {
	os.is_writable_folder('.') or {
		println('🧨 Folder is not writable. Exiting.')
		exit(1)
	}
}

// Set up a basic gitignore if one isn't present
fn setup_gitignore() {
	print('📄 Checking for a gitignore…')
	os.flush()
	if os.exists('.gitignore') {
		println(' found!')
	} else {
		print(' missing… creating…')
		os.flush()
		os.write_file('.gitignore', sample_gitignore)
		println(' done!')
	}
}

// Create endpoints folder with example if empty
fn setup_endpoints() {
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
		os.write_file('endpoints/hello.v', sample_endpoint)
		println(' done!')
	} else if os.is_dir('endpoints') && os.is_dir_empty('endpoints') {
		print(' found empty… adding sample…')
		os.flush()
		os.write_file('endpoints/hello.v', sample_endpoint)
		println(' done!')
	} else {
		println(' found!')
	}
}

// Merges all endpoint files into one file
fn merge() {
	println('🔪 Dissecting handlers…')
	// Build two separate sections for the dev server file
	mut imports := ['import exastencil.vape']
	mut handlers := []string{}
	// Split and merge all endpoints into these sections
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
	output.writeln('\n// Server')
	output.writeln('server := vape.Server{port: 6789}')
	output.writeln('\n// Handlers')
	for line in handlers {
		output.writeln(line)
	}
	output.writeln('server.serve()')
	output.close()
}

fn compile() {
	println('🧠 Compiling development server…')
	os.system('v build/dev.v')
}

fn launch() {
	if os.exists('build/dev') {
		println('🚀 Launching development server on port 6789… Ctrl + C to exit.')
		os.system('build/dev')
	}
}
