import React from 'react'
import {List, Label, Icon, Divider} from 'semantic-ui-react'

class AwesomeList extends React.Component {
  render() {
    let date_diff = (date) => ( new Date().getTime() - new Date(date).getTime() ) / (1000 * 3600 * 24)

    let sublist = (item, i) =>
     <List.Item key={"link_" + item.name + i}>
       <List.Content>
         <a href={item.href}><b>{item.name}</b></a>
         <Label basic basic style={{ marginLeft: '1em', minWidth: '6em' }}>
           <Icon name='star' color='yellow'/> {item.stars}
         </Label>
         <Label basic><Icon name='calendar outline'/> {parseInt(date_diff(item.last_commit))}</Label>
         <br/>
         <div className="description">{item.desc}</div>
         <Divider/>
       </List.Content>
     </List.Item>

    let list = (item, i) =>
      <List.Item key={"title_" + item.title + i} style={{ paddingLeft: '3.5em' }}>
        <List.Content>
          <List.Header as='h3' id={item.title}>{item.title}</List.Header>
          <List.Description>{item.desc}</List.Description>
        </List.Content>
        <List.List children>{item.links.map(sublist)}</List.List>
      </List.Item>

    return <List>{this.props.items.map(list)}</List>
  }
}
export default AwesomeList
