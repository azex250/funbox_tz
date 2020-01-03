import "phoenix_html"
import socket from "./socket"

import ReactDOM from 'react-dom'
import React from 'react'
import Index from './components/index'
import {BrowserRouter, useLocation, Route} from "react-router-dom";

function useQuery() {
  return new URLSearchParams(useLocation().search);
}

const IndexPage = () => {
  let query = useQuery()

  return (
    <BrowserRouter>
     <Index stars={query.get("stars")} />
    </BrowserRouter>
  )
}

ReactDOM.render(
  <BrowserRouter>
    <Route path='/' component={IndexPage} />
  </BrowserRouter>,
  document.getElementById('mountPoint')
)
