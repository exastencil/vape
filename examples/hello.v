import exastencil.vape
import net.http

fn hello(req http.Request) http.Response {
	return http.Response{
		headers: {
			'Content-Type': 'text/plain'
		}
		text: 'Hello World'
		status_code: 200
	}
}

fn world(req http.Request) http.Response {
	return http.Response{
		headers: {
			'Content-Type': 'application/json'
		}
		text: "{ hello: 'World!' }"
		status_code: 200
	}
}

server := vape.Server{
	port: 8080
	endpoints: [
		vape.Endpoint{
			path: '/hello'
			handler: hello
		},
		vape.Endpoint{
			path: '/world'
			handler: world
		}
	]
}
server.serve()
