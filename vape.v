module vape

import net
import net.http
import net.urllib
import strings

const (
	http_statuses = {
		'200': 'OK'
		'302': 'Found'
		'400': 'Bad Request'
		'404': 'Not Found'
		'500': 'Internal Server Error'
	}
	NOT_FOUND     = http.Response{
		status_code: 404
		text: '404 Not Found'
		headers: {
			'Content-Type': 'text/plain'
		}
	}
	BAD_REQUEST   = http.Response{
		status_code: 400
		text: '400 Bad Request'
		headers: {
			'Content-Type': 'text/plain'
		}
	}
)

pub type Handler = fn (req http.Request) http.Response

pub struct Endpoint {
	host    string = '127.0.0.1'
	path    string = '/'
	handler Handler
}

pub struct Server {
	port      int
	endpoints []Endpoint
}

pub fn (s Server) serve() {
	l := net.listen(s.port) or {
		panic('failed to listen')
	}
	for {
		socket := l.accept() or {
			panic('connection failed')
		}
		request := parse_request(socket) or {
			http.Request{}
		}
		response := s.handle_request(request)
		send_response(response, socket)
	}
}

fn parse_request(socket net.Socket) ?http.Request {
	first_line := socket.read_line()
	// Parse the first line
	// "GET / HTTP/1.1"
	vals := first_line.split(' ')
	if vals.len < 2 {
		return error('vape.parse_request: Not enough information in request')
	}
	mut headers := []string{}
	mut body := ''
	mut in_headers := true
	mut len := 0
	mut body_len := 0
	for _ in 0 .. 100 {
		line := socket.read_line()
		sline := line.trim('\r\n')
		if sline == '' {
			if len == 0 {
				break
			}
			in_headers = false
		}
		if in_headers {
			headers << sline
			if sline.starts_with('Content-Length') {
				len = sline.all_after(': ').int()
			}
		} else {
			body += sline + '\r\n'
			body_len += body.len
			if body_len >= len {
				break
			}
		}
	}
	return http.Request{
		headers: http.parse_headers(headers)
		data: body.trim('\r\n')
		ws_func: 0
		user_ptr: 0
		method: vals[0]
		url: vals[1]
	}
}

fn (s Server) handle_request(request http.Request) http.Response {
	print('[$request.method $request.url]')
	url := urllib.parse(request.url) or {
		return BAD_REQUEST
	}
	for endpoint in s.endpoints {
		if endpoint.path == url.path {
			return endpoint.handler(request)
		}
	}
	return NOT_FOUND
}

fn send_response(response http.Response, socket net.Socket) {
	println(' => <$response.status_code $response.text>')
	mut buffer := strings.new_builder(1024)
	defer {
		buffer.free()
	}
	buffer.write('HTTP/1.1 $response.status_code ${http_statuses[response.status_code.str()]}\r\n')
	buffer.write('Content-Length: $response.text.len\r\n')
	for key, value in response.headers {
		buffer.write('$key: $value\r\n')
	}
	buffer.write('Server: vape\r\n')
	buffer.write('Connection: close\r\n')
	buffer.write('\r\n')
	buffer.write(response.text.str())
	socket.send_string(buffer.str()) or {
		// TODO: Log an error
	}
	socket.close() or {
		// TODO: Log an error
	}
}
