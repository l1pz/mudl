import jester
import htmlgen

routes:
  get "/":
    resp h1("Hello world")