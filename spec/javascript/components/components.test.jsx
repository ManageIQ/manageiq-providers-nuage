import React from 'react';
import { shallow } from 'enzyme';
import toJson from 'enzyme-to-json';

import { Spinner } from 'patternfly-react';

describe('<Spinner/>', () => {
  it('renders <Spinner> component', () => {
    expect(toJson(shallow(<Spinner loading />))).toMatchSnapshot();
  });
});
