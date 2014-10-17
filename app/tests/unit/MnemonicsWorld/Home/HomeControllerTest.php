<?php

class HomeControllerTest
    extends TestCase
{
    public function testIndexAction()
    {
        $response = $this->action(
            'GET',
            'MnemonicsWorld\Home\HomeController@getIndex'
        );
        $this->assertEquals($response->getStatusCode(), 200);
    }
}