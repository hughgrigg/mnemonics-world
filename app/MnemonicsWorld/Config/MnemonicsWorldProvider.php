<?php namespace MnemonicsWorld\Config;
use Illuminate\Support\ServiceProvider;
use View;

class MnemonicsWorldProvider
    extends ServiceProvider
{
    public function register()
    {
        View::addNamespace(
            'mnemonicsworld', app('path') . '/MnemonicsWorld/views'
        );
    }
}