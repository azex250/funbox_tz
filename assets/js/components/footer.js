import React from 'react'
import {List, Container} from 'semantic-ui-react'

class Footer extends React.Component {
  render() {
    return (
      <Container textAlign="center">
        <List horizontal footer='true' divided link size='small'>
         <List.Item as='a' href='https://github.com/azex250' target='blank'>
           Sergey Sychev (c) 2020
         </List.Item>
        </List>
      </Container>
    )
  }
}
export default Footer
