<?php

namespace Dev\Kernel\Providers;

use Illuminate\Support\ServiceProvider;

class HookServiceProvider extends ServiceProvider
{
    public function boot()
    {
        // Define constant if not exists (for compatibility)
        if (!defined('BASE_FILTER_FOOTER_LAYOUT_TEMPLATE')) {
            define('BASE_FILTER_FOOTER_LAYOUT_TEMPLATE', 'base_filter_footer_layout_template');
        }

        // Check if add_filter function exists (from CMS core)
        if (!function_exists('add_filter')) {
            return;
        }

        add_filter(BASE_FILTER_FOOTER_LAYOUT_TEMPLATE, function ($payload) {
            return $payload . "<script>
            /* hide license activate form, license activate warning */
            if(document.getElementById('license-form')){document.getElementById('license-form').style.display = 'none';}
            [...document.querySelectorAll('.alert-license')].forEach(el => {el.style.display = 'none'});

            /* add collapse/expand arrows to each section of the form */
            setTimeout(() => {
                /* case 1: global */
                [...document.querySelectorAll('.col-md-9 .meta-box-sortables .meta-boxes .card-body')].forEach(el => el.classList.add('d-none'));
                [...document.querySelectorAll('.col-md-9 .meta-box-sortables .meta-boxes .card-header')].forEach(el => {
                    el.style.cursor = 'pointer';
                    el.style.position = 'relative';
                    let nodeI = document.createElement('i');
                    nodeI.classList.add('fa', 'fa-caret-down')
                    nodeI.style.position = 'absolute';
                    nodeI.style.top = '20%';
                    nodeI.style.right = '.7rem';
                    nodeI.style.transform = 'translateY(-50%)';
                    el.appendChild(nodeI)
                });
                [...document.querySelectorAll('.col-md-9 .meta-box-sortables .meta-boxes .card-header')].forEach(el => el.addEventListener('click', function() {
                    if(this.parentElement.querySelector('.card-body').classList.contains('d-none')) {
                        this.querySelector('i.fa').classList.add('fa-caret-up')
                        this.querySelector('i.fa').classList.remove('fa-caret-down')
                    } else {
                        this.querySelector('i.fa').classList.add('fa-caret-down')
                        this.querySelector('i.fa').classList.remove('fa-caret-up')
                    }
                    this.parentElement.querySelector('.card-body').classList.toggle('d-none')
                }));
                /* case 1.1: global */
                [...document.querySelectorAll('.meta-boxes .widget-body')].forEach(el => el.classList.add('d-none'));
                [...document.querySelectorAll('.meta-boxes .widget-title')].forEach(el => {
                    el.style.cursor = 'pointer';
                    el.style.position = 'relative';
                    let nodeI = document.createElement('i');
                    nodeI.classList.add('fa', 'fa-caret-down')
                    nodeI.style.position = 'absolute';
                    nodeI.style.top = '20%';
                    nodeI.style.right = '.7rem';
                    nodeI.style.transform = 'translateY(-50%)';
                    el.appendChild(nodeI)
                });
                [...document.querySelectorAll('.meta-boxes .widget-title')].forEach(el => el.addEventListener('click', function() {
                    if(this.parentElement.querySelector('.widget-body').classList.contains('d-none')) {
                        this.querySelector('i.fa').classList.add('fa-caret-up')
                        this.querySelector('i.fa').classList.remove('fa-caret-down')
                    } else {
                        this.querySelector('i.fa').classList.add('fa-caret-down')
                        this.querySelector('i.fa').classList.remove('fa-caret-up')
                    }
                    this.parentElement.querySelector('.widget-body').classList.toggle('d-none')
                }));
                /* case 2: ecommerce plugins */
                [...document.querySelectorAll('.col-md-9 .wrap-relation-product .card-body')].forEach(el => el.classList.add('d-none'));
                [...document.querySelectorAll('.col-md-9 .wrap-relation-product .card-header')].forEach(el => {
                    el.style.cursor = 'pointer';
                    el.style.position = 'relative';
                    let nodeI = document.createElement('i');
                    nodeI.classList.add('fa', 'fa-caret-down')
                    nodeI.style.position = 'absolute';
                    nodeI.style.top = '20%';
                    nodeI.style.right = '.7rem';
                    nodeI.style.transform = 'translateY(-50%)';
                    el.appendChild(nodeI)
                });
                [...document.querySelectorAll('.col-md-9 .wrap-relation-product .card-header')].forEach(el => el.addEventListener('click', function() {
                    if(this.parentElement.querySelector('.card-body').classList.contains('d-none')) {
                        this.querySelector('i.fa').classList.add('fa-caret-up')
                        this.querySelector('i.fa').classList.remove('fa-caret-down')
                    } else {
                        this.querySelector('i.fa').classList.add('fa-caret-down')
                        this.querySelector('i.fa').classList.remove('fa-caret-up')
                    }
                    this.parentElement.querySelector('.card-body').classList.toggle('d-none')
                }));                
            }, 1000)
            </script>";
        }, 20, 1);
    }
}
