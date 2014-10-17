<?php namespace MnemonicsWorld\Home;
use Controller;
use View;

class HomeController
    extends Controller
{
    public function getIndex()
    {
        return View::make('mnemonicsworld::home.home');
    }
}