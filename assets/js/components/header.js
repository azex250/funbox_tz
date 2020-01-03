import React from 'react'
import { Menu, Dropdown, Image } from 'semantic-ui-react'

class Header extends React.Component {
  render() {
    return (
      <Menu fixed='top'>
        <Menu.Item header>
          <Image size='mini' src="/images/elixir.png" style={{ marginRight: '1.5em' }} />
          Awesome Elixir Mirror
        </Menu.Item>
        <Menu.Item as='a' href='/'>All</Menu.Item>
        <Menu.Item as='a' href='/?stars=10'>≥10⭐</Menu.Item>
        <Menu.Item as='a' href='/?stars=50'>≥50⭐</Menu.Item>
        <Menu.Item as='a' href='/?stars=100'>≥100⭐</Menu.Item>
        <Menu.Item as='a' href='/?stars=200'>≥200⭐</Menu.Item>
        <Menu.Item as='a' href='/?stars=500'>≥500⭐</Menu.Item>
        <Menu.Item as='a' href='/?stars=1000'>≥1000⭐</Menu.Item>
        <Menu.Item as='a' position='right' href='https://github.com/h4cc/awesome-elixir' target='blank'>
         <Image size='mini' src="/images/github.jpg" style={{ marginRight: '1.5em' }} />
           Awesome Repo
        </Menu.Item>
      </Menu>
    )
  }
}
export default Header
