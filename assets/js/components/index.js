import React from 'react'
import { Grid } from 'semantic-ui-react'
import Header from './header'
import AwesomeList from './awesome_list'
import Footer from './footer'
import socket from "../socket"

class Index extends React.Component {
  constructor(props) {
    console.log("new stars");
    super(props)
    this.state = {items: []}

    let stars = props.stars
    let channel = socket.channel('github:update', {})

    channel.join()
      .receive("ok", resp => { console.log("Joined successfully", resp) })
      .receive("error", resp => { console.log("Unable to join", resp) })

    channel.on(
      'new_status', msg => {
        console.log(msg);
        this.setState({items: msg.response})
      }
    )

    channel.on('outdated', _msg => {
      console.log(stars);
      () => channel.push('get_status', stars ? {"stars": stars} : {})
    })

    channel.push('get_status', stars ? {"stars": stars} : {})
  }

  render() {
    return (
      <Grid>
        <Grid.Row style={{ paddingTop: '3.5em' }}>
          <Header />
        </Grid.Row>
        <Grid.Row>
          <Grid.Column width={16} >
            <AwesomeList items={this.state.items} />
          </Grid.Column>
        </Grid.Row>
        <Grid.Row>
          <Footer />
        </Grid.Row>
      </Grid>
    )
  }
}
export default Index
