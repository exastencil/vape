module vape

import net
import strings

const (
	version = '0.2.1'
)

// Request is passed as input to a Handler
pub struct Request {
	pub:
		method string = 'GET'
		host string
		path string
		query map[string]string
		form map[string]string
		body string
		headers map[string]string
}

fn (req Request) url() string {
	return '$req.host$req.path'
}

// Response is the return value of a Handler
pub struct Response {
	pub mut:
		status int = 200
		body string = ''
		content_type string = 'text/plain; charset=utf-8'
		headers map[string]string
}

fn http_status_descriptor(status int) string {
	msg := match status {
		100 { 'Continue' }
		101 { 'Switching Protocols' }
		200 { 'OK' }
		201 { 'Created' }
		202 { 'Accepted' }
		203 { 'Non-Authoritive Information' }
		204 { 'No Content' }
		205 { 'Reset Content' }
		206 { 'Partial Content' }
		300 { 'Multiple Choices' }
		301 { 'Moved Permanently' }
		400 { 'Bad Request' }
		401 { 'Unauthorized' }
		403 { 'Forbidden' }
		404 { 'Not Found' }
		405 { 'Method Not Allowed' }
		408 { 'Request Timeout' }
		500 { 'Internal Server Error' }
		501 { 'Not Implemented' }
		502 { 'Bad Gateway' }
		else { '-' }
	}
	return msg
}

// This function can be used to quickly build a response with a specific status
pub fn response(status int, content_type string) Response {
	return Response{
		status: status
		body: '$status ${http_status_descriptor(status)}'
		headers: {
			'Content-Type': content_type
		}
	}
}

pub type Handler = fn (req Request) Response

pub struct Endpoint {
	host    string = '127.0.0.1'
	path    string = '/'
	method  string = 'GET'
	handler Handler
}

// Mount a request handler at a path
pub fn (mut s Server) mount(method string, path string, handler Handler) {
	s.endpoints << Endpoint {
		path: path
		method: method
		handler: handler
	}
}

pub struct Server {
	port      int
	pub mut:
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
			Request{}
		}
		response := s.handle_request(request)
		send_response(response, socket)
	}
}

fn parse_request(socket net.Socket) ?Request {
	first_line := socket.read_line()
	// Parse the first line
	// "GET / HTTP/1.1"
	vals := first_line.split(' ')
	if vals.len < 2 {
		return error('vape.parse_request: Not enough information in request')
	}
	mut headers := map[string]string{}
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
			words := sline.split(': ')
			if words.len == 2 {
				headers[words[0]] = words[1]
			}
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
	return Request{
		headers: headers
		body: body.trim('\r\n')
		method: vals[0]
		path: vals[1]
	}
}

fn (s Server) handle_request(request Request) Response {
	print('[$request.method ${request.url()}]')
	for endpoint in s.endpoints {
		if endpoint.path == request.path {
			return endpoint.handler(request)
		}
	}
	return response(404, 'text/plain; charset=utf-8')
}

fn send_response(response Response, socket net.Socket) {
	println(' => <$response.status $response.body>')
	mut buffer := strings.new_builder(1024)
	defer {
		buffer.free()
	}
	buffer.write('HTTP/1.1 $response.status ${http_status_descriptor(response.status)}\r\n')
	buffer.write('Content-Length: $response.body.len\r\n')
	for key, value in response.headers {
		buffer.write('$key: $value\r\n')
	}
	buffer.write('Server: vape\r\n')
	buffer.write('Connection: close\r\n')
	buffer.write('\r\n')
	buffer.write(response.body.str())
	socket.send_string(buffer.str()) or {
		// TODO: Log an error
	}
	socket.close() or {
		// TODO: Log an error
	}
}
