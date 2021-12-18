import * as React from "react"
import * as ReactDOM from "react-dom"
import styled from "styled-components"
import * as AkNavigation from "@atlaskit/navigation-next"
import * as AkGlobalNavigation from '@atlaskit/global-navigation';

import { AtlassianIcon } from '@atlaskit/logo';

import Button from "./components/Button"


const {
    LayoutManager,
    NavigationProvider,
    GroupHeading,
    HeaderSection,
    Item,
    MenuSection,
    Separator,
} = AkNavigation;

const Block = styled.div`
    padding: 10px;
`

interface Props {
    name?: string
}

interface State {
}

const MyGlobalNavigation = () => (
    <AkGlobalNavigation.default
        productIcon={() => <AtlassianIcon size="medium" />}
        onProductClick={() => { }}
    />
);

const MyProductNavigation = () => (
    <React.Fragment>
        <HeaderSection>
            {({ className }) => (
                <div className={className}>
                    <Item text="Profile" />
                    <Item text="Settings" />
                    <Separator />
                </div>
            )}
        </HeaderSection>
        <MenuSection>
            {({ className }) => (
                <div className={className}>
                    <Item text="Dashboard" />
                    <Item text="Things" />
                    <Separator />
                    <GroupHeading>Add-ons</GroupHeading>
                    <Item text="My plugin" />
                    <Item text="Settings" />
                </div>
            )}
        </MenuSection>
    </React.Fragment>
);

class App extends React.PureComponent<Props, State> {
    props: Props = {}
    state: State = {}

    constructor(props, context) {
        super(props, context)
    }

    render(): any {
        return <NavigationProvider>
            <LayoutManager
                globalNavigation={MyGlobalNavigation}
                productNavigation={MyProductNavigation}
                containerNavigation={MyProductNavigation}
            >
                <Block>
                    <AtlassianIcon size="medium" />
                    <Button>{this.props.name}</Button>
                </Block>
            </LayoutManager>
        </NavigationProvider>;
    }

}


ReactDOM.render(<App name="Jane Doe" />, document.getElementById("app"));