import os
from flask import Flask, request

app = Flask(__name__)

@app.route('/hello')
def hello_world():
    """
    Public endpoint that greets the world.
    """
    return 'Hello World from Flask!'

@app.route('/health')
def health():
    """
    Internal endpoint for health check.
    """
    return 'OK' if os.environ.get('HEALTH_TOKEN') == 'foo' else 'KO'

@app.route('/fib')
def fib_handler():
    """
    Internal endpoint for fibonacchi calculation without anylimit.
    """
    n = request.args.get('n')
    return str(fib(int(n)))

def fib(n):
    """
    Gloriously inefficient fibonacci function
    """
    if n<0: 
        raise ValueError("Incorrect input") 
    elif n==0: 
        return 0
    elif n==1: 
        return 1
    else: 
        return fib(n-1)+fib(n-2) 

if __name__ == '__main__':
    app.run()

