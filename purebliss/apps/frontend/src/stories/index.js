import React from 'react';
import { storiesOf } from '@storybook/react-native';
import { Text } from 'react-native';

storiesOf('Hello', module).add('world', () => <Text>Hello Storybook!</Text>);
